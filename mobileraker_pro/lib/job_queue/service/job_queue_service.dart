/*
 * Copyright (c) 2024-2026. Patrick Schmidt.
 * All rights reserved.
 */

import 'dart:async';

import 'package:common/data/dto/job_queue/job_queue_entry.dart';
import 'package:common/data/dto/job_queue/job_queue_event.dart';
import 'package:common/data/dto/job_queue/job_queue_status.dart';
import 'package:common/network/json_rpc_client.dart';
import 'package:common/network/jrpc_client_provider.dart';
import 'package:common/service/selected_machine_service.dart';
import 'package:common/util/logger.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class _JobQueueServiceFamily {
  Provider<JobQueueService> call(String machineUUID) => _family(machineUUID);

  static final _family = Provider.family<JobQueueService, String>(
    (ref, machineUUID) => JobQueueService(ref, machineUUID),
  );
}

final jobQueueServiceProvider = _JobQueueServiceFamily();

class _JobQueueFamily {
  StreamProvider<JobQueueStatus> call(String machineUUID) => _family(machineUUID);

  static final _family = StreamProvider.family<JobQueueStatus, String>(
    (ref, machineUUID) => ref.watch(jobQueueServiceProvider(machineUUID)).statusStream,
  );
}

final jobQueueProvider = _JobQueueFamily();

class _JobQueueServiceSelectedFamily {
  Provider<JobQueueService?> call() => _selected;

  static final _selected = Provider<JobQueueService?>((ref) {
    final machine = ref.watch(selectedMachineProvider).value;
    if (machine == null) return null;
    return ref.watch(jobQueueServiceProvider(machine.uuid));
  });
}

/// Serviço da fila da impressora "selecionada" (ou `null`).
final jobQueueServiceSelectedProvider = _JobQueueServiceSelectedFamily();

/// Estado da fila da impressora "selecionada".
final jobQueueSelectedProvider = FutureProvider<JobQueueStatus>((ref) async {
  final service = ref.watch(jobQueueServiceSelectedProvider());
  if (service == null) {
    return JobQueueStatus(queuedJobs: const <JobQueueEntry>[], queueState: QueueState.ready);
  }
  return service.queueStatus();
});

/// Fila de impressão do Moonraker (`server.job_queue.*`).
///
/// Contrato extraído do APK oficial (mobileraker 2.9.14):
/// - `server.job_queue.status`     — estado atual
/// - `server.job_queue.post_job`   — enfileirar (`filenames`, `reset`)
/// - `server.job_queue.delete_job` — remover (`job_ids`)
/// - `server.job_queue.pause`      — pausar
/// - `server.job_queue.start`      — iniciar/retomar
/// - Notificação `notify_job_queue_changed` (`status` + `event`)
class JobQueueService {
  JobQueueService(this._ref, this.machineUUID) {
    _ref.listen<JsonRpcClient>(
      jrpcClientProvider(machineUUID),
      (previous, next) => _attach(next),
      fireImmediately: true,
    );
    _ref.onDispose(_dispose);
  }

  final Ref _ref;
  final String machineUUID;

  final StreamController<JobQueueStatus> _statusController = StreamController<JobQueueStatus>.broadcast();
  final StreamController<JobQueueEvent> _eventController = StreamController<JobQueueEvent>.broadcast();

  JsonRpcClient? _client;
  StreamSubscription<ClientState>? _clientStateSubscription;

  JobQueueStatus? _lastStatus;

  String get logPrefix => '[JobQueueService($machineUUID)]';

  /// Estado atual (repassado logo ao escutar) seguido das atualizações.
  Stream<JobQueueStatus> get statusStream async* {
    yield _lastStatus ?? JobQueueStatus(queuedJobs: const <JobQueueEntry>[], queueState: QueueState.ready);
    yield* _statusController.stream;
  }

  /// Mantém o nome original da API do pacote PRO (com o typo histórico).
  Stream<JobQueueEvent> get queueChagendEventStream => _eventController.stream;

  JobQueueStatus _emit(JobQueueStatus status) {
    _lastStatus = status;
    if (!_statusController.isClosed) _statusController.add(status);
    return status;
  }

  JobQueueStatus _statusFromResult(Map<String, dynamic> result) {
    final nested = result['status'];
    if (result['queued_jobs'] == null && nested is Map) {
      return JobQueueStatus.fromJson(Map<String, dynamic>.from(nested));
    }
    return JobQueueStatus.fromJson(result);
  }

  Future<JobQueueStatus> queueStatus() async {
    talker.debug('$logPrefix Queue status request...');
    try {
      final response = await _requireClient().sendJRpcMethod('server.job_queue.status');
      return _emit(_statusFromResult(response.result));
    } catch (e, s) {
      talker.error('$logPrefix Unable to fetch job queue status', e, s);
      rethrow;
    }
  }

  Future<JobQueueStatus> enqueueJob(String file, [bool reset = false]) => enqueueJobs([file], reset);

  Future<JobQueueStatus> enqueueJobs(List<String> files, [bool reset = false]) async {
    talker.debug('$logPrefix Trying to enqueue files $files...');
    try {
      final response = await _requireClient().sendJRpcMethod(
        'server.job_queue.post_job',
        params: {'filenames': files, 'reset': reset},
      );
      return _emit(_statusFromResult(response.result));
    } catch (e, s) {
      talker.error('$logPrefix Error while adding files $files to the queue', e, s);
      rethrow;
    }
  }

  Future<JobQueueStatus> dequeueJob(String jobId) => dequeueJobs([jobId]);

  Future<JobQueueStatus> dequeueJobs(List<String> jobIds) async {
    talker.debug('$logPrefix Trying to dequeue files $jobIds...');
    try {
      final response = await _requireClient().sendJRpcMethod(
        'server.job_queue.delete_job',
        params: {'job_ids': jobIds},
      );
      return _emit(_statusFromResult(response.result));
    } catch (e, s) {
      talker.error('$logPrefix Error while removing jobs $jobIds from the queue', e, s);
      rethrow;
    }
  }

  Future<JobQueueStatus> pauseQueue() async {
    talker.debug('$logPrefix Trying to pause queue...');
    try {
      final response = await _requireClient().sendJRpcMethod('server.job_queue.pause');
      return _emit(_statusFromResult(response.result));
    } catch (e, s) {
      talker.error('$logPrefix Error while pausing the queue', e, s);
      rethrow;
    }
  }

  Future<JobQueueStatus> startQueue() async {
    talker.debug('$logPrefix Trying to start queue...');
    try {
      final response = await _requireClient().sendJRpcMethod('server.job_queue.start');
      return _emit(_statusFromResult(response.result));
    } catch (e, s) {
      talker.error('$logPrefix Error while starting the queue', e, s);
      rethrow;
    }
  }

  // -- Internos -------------------------------------------------------------

  JsonRpcClient _requireClient() {
    final client = _client;
    if (client == null) {
      throw StateError('JsonRpcClient is not available');
    }
    return client;
  }

  void _attach(JsonRpcClient client) {
    _clientStateSubscription?.cancel();
    _client?.removeMethodListener(_onJobQueueChanged, 'notify_job_queue_changed');
    _client = client;
    client.addMethodListener(_onJobQueueChanged, 'notify_job_queue_changed');
    _clientStateSubscription = client.stateStream.listen(_onClientStateChanged);
    if (client.curState == ClientState.connected) _refreshQueueStatus();
  }

  void _onClientStateChanged(ClientState state) {
    if (state != ClientState.connected) return;
    talker.debug('$logPrefix Client connected. Refreshing queue status...');
    _refreshQueueStatus();
  }

  void _refreshQueueStatus() {
    _refreshQueueStatusInternal();
  }

  Future<void> _refreshQueueStatusInternal() async {
    try {
      await queueStatus();
    } catch (e, s) {
      talker.error('$logPrefix Error while refreshing queue status after an connection event', e, s);
    }
  }

  void _onJobQueueChanged(Map<String, dynamic> rawMessage) {
    final params = _firstParams(rawMessage);
    if (params == null) return;
    final statusJson = params['status'];
    if (statusJson is Map) {
      _emit(_statusFromResult(Map<String, dynamic>.from(statusJson)));
    }
    final eventJson = params['event'];
    if (eventJson is Map) {
      final event = JobQueueEvent.fromJson(Map<String, dynamic>.from(eventJson));
      talker.debug('$logPrefix onJobQueueChanged Event: $event');
      if (!_eventController.isClosed) _eventController.add(event);
    }
  }

  Map<String, dynamic>? _firstParams(Map<String, dynamic> rawMessage) {
    final params = rawMessage['params'];
    if (params is List && params.isNotEmpty) {
      final first = params.first;
      if (first is Map) return Map<String, dynamic>.from(first);
    }
    if (params is Map) return Map<String, dynamic>.from(params);
    return null;
  }

  void _dispose() {
    _clientStateSubscription?.cancel();
    _client?.removeMethodListener(_onJobQueueChanged, 'notify_job_queue_changed');
    _statusController.close();
    _eventController.close();
  }
}
