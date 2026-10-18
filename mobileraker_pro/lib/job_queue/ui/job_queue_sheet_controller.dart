/*
 * Copyright (c) 2024-2026. Patrick Schmidt.
 * All rights reserved.
 */

import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../service/job_queue_service.dart';

class _JobQueueSheetControllerFamily {
  Provider<JobQueueSheetController> call() => _controller;

  static final _controller = Provider<JobQueueSheetController>((ref) => JobQueueSheetController(ref));
}

/// Controlador da sheet da fila de impressão.
final jobQueueSheetControllerProvider = _JobQueueSheetControllerFamily();

/// Executa as ações da fila do Moonraker (`server.job_queue.*`).
class JobQueueSheetController {
  JobQueueSheetController(this._ref);

  final Ref _ref;

  JobQueueService? get _service => _ref.read(jobQueueServiceSelectedProvider());

  Future<void> startQueue() async {
    final future = _service?.startQueue();
    if (future != null) await future;
  }

  Future<void> pauseQueue() async {
    final future = _service?.pauseQueue();
    if (future != null) await future;
  }

  Future<void> removeJob(String jobId) async {
    final future = _service?.dequeueJob(jobId);
    if (future != null) await future;
  }

  Future<void> removeJobs(List<String> jobIds) async {
    if (jobIds.isEmpty) return;
    final future = _service?.dequeueJobs(jobIds);
    if (future != null) await future;
  }
}
