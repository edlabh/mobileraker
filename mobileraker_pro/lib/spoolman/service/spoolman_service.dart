/*
 * Copyright (c) 2024-2026. Patrick Schmidt.
 * All rights reserved.
 */

import 'dart:async';

import 'package:common/network/json_rpc_client.dart';
import 'package:common/network/jrpc_client_provider.dart';
import 'package:common/data/dto/pagination_result.dart';
import 'package:common/util/logger.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../dto/create_filament.dart';
import '../dto/create_spool.dart';
import '../dto/create_vendor.dart';
import '../dto/get_extra_field.dart';
import '../dto/get_filament.dart';
import '../dto/get_spool.dart';
import '../dto/get_vendor.dart';
import '../dto/spoolman_entity_type_enum.dart';
import '../dto/spoolman_filter.dart';
import '../dto/update_filament.dart';
import '../dto/update_spool.dart';
import '../dto/update_vendor.dart';
import '../../misc/json_util.dart' show JsonUtil;
import '../repository/filament_repository.dart';
import '../repository/spool_repository.dart';
import '../repository/vendor_repository.dart';

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

class _SpoolmanServiceFamily {
  Provider<SpoolmanService> call(String machineUUID) => _family(machineUUID);

  static final _family = Provider.family<SpoolmanService, String>((ref, machineUUID) {
    return SpoolmanService(
      ref,
      machineUUID,
      jsonRpcClient: ref.watch(jrpcClientProvider(machineUUID)),
      spoolRepository: ref.watch(spoolRepositoryProvider(machineUUID)),
      filamentRepository: ref.watch(filamentRepositoryProvider(machineUUID)),
      vendorRepository: ref.watch(vendorRepositoryProvider(machineUUID)),
    );
  });
}

final spoolmanServiceProvider = _SpoolmanServiceFamily();

class _SpoolmanCurrencyFamily {
  Provider<String> call(String machineUUID) => _family(machineUUID);

  static final _family = Provider.family<String, String>((ref, machineUUID) {
    final service = ref.watch(spoolmanServiceProvider(machineUUID));
    final sub = service.changes.listen((_) => ref.invalidateSelf());
    ref.onDispose(sub.cancel);
    return service.currency;
  });
}

final spoolmanCurrencyProvider = _SpoolmanCurrencyFamily();

class _SpoolmanExtraFieldsFamily {
  FutureProvider<List<GetExtraField>> call(String machineUUID, SpoolmanEntityType type) =>
      _family((machineUUID, type));

  static final _family = FutureProvider.family<List<GetExtraField>, (String, SpoolmanEntityType)>((ref, key) {
    final service = ref.watch(spoolmanServiceProvider(key.$1));
    return service.getExtraFieldsFor(key.$2);
  });
}

final spoolmanExtraFieldsProvider = _SpoolmanExtraFieldsFamily();

class _SpoolListFamily {
  FutureProvider<PaginationResult<GetSpool>> call(
    String machineUUID, {
    int? page,
    int? pageSize,
    SpoolmanFilter? filters,
  }) =>
      _family((machineUUID, page, pageSize, filters));

  static final _family =
      FutureProvider.family<PaginationResult<GetSpool>, (String, int?, int?, SpoolmanFilter?)>((ref, key) {
    final service = ref.watch(spoolmanServiceProvider(key.$1));
    final sub = service.changes.listen((_) => ref.invalidateSelf());
    ref.onDispose(sub.cancel);
    return service.spoolList(page: key.$2, pageSize: key.$3, filters: key.$4);
  });
}

final spoolListProvider = _SpoolListFamily();

class _FilamentListFamily {
  FutureProvider<PaginationResult<GetFilament>> call(
    String machineUUID, {
    int? page,
    int? pageSize,
    SpoolmanFilter? filters,
  }) =>
      _family((machineUUID, page, pageSize, filters));

  static final _family =
      FutureProvider.family<PaginationResult<GetFilament>, (String, int?, int?, SpoolmanFilter?)>((ref, key) {
    final service = ref.watch(spoolmanServiceProvider(key.$1));
    final sub = service.changes.listen((_) => ref.invalidateSelf());
    ref.onDispose(sub.cancel);
    return service.filamentList(page: key.$2, pageSize: key.$3, filters: key.$4);
  });
}

final filamentListProvider = _FilamentListFamily();

class _VendorListFamily {
  FutureProvider<PaginationResult<GetVendor>> call(
    String machineUUID, {
    int? page,
    int? pageSize,
    SpoolmanFilter? filters,
  }) =>
      _family((machineUUID, page, pageSize, filters));

  static final _family =
      FutureProvider.family<PaginationResult<GetVendor>, (String, int?, int?, SpoolmanFilter?)>((ref, key) {
    final service = ref.watch(spoolmanServiceProvider(key.$1));
    final sub = service.changes.listen((_) => ref.invalidateSelf());
    ref.onDispose(sub.cancel);
    return service.vendorList(page: key.$2, pageSize: key.$3, filters: key.$4);
  });
}

final vendorListProvider = _VendorListFamily();

class _ActiveSpoolFamily {
  StreamProvider<GetSpool?> call(String machineUUID) => _family(machineUUID);

  static final _family = StreamProvider.family<GetSpool?, String>(
    (ref, machineUUID) => ref.watch(spoolmanServiceProvider(machineUUID)).activeSpoolStream,
  );
}

final activeSpoolProvider = _ActiveSpoolFamily();

class _SpoolFamily {
  FutureProvider<GetSpool?> call(String machineUUID, int id) => _family((machineUUID, id));

  static final _family = FutureProvider.family<GetSpool?, (String, int)>((ref, key) {
    final service = ref.watch(spoolmanServiceProvider(key.$1));
    final sub = service.changes.listen((_) => ref.invalidateSelf());
    ref.onDispose(sub.cancel);
    return service.fetchSpool(key.$2);
  });
}

final spoolProvider = _SpoolFamily();

class _FilamentFamily {
  FutureProvider<GetFilament?> call(String machineUUID, int id) => _family((machineUUID, id));

  static final _family = FutureProvider.family<GetFilament?, (String, int)>((ref, key) {
    final service = ref.watch(spoolmanServiceProvider(key.$1));
    final sub = service.changes.listen((_) => ref.invalidateSelf());
    ref.onDispose(sub.cancel);
    return service.fetchFilament(key.$2);
  });
}

final filamentProvider = _FilamentFamily();

class _VendorFamily {
  FutureProvider<GetVendor?> call(String machineUUID, int id) => _family((machineUUID, id));

  static final _family = FutureProvider.family<GetVendor?, (String, int)>((ref, key) {
    final service = ref.watch(spoolmanServiceProvider(key.$1));
    final sub = service.changes.listen((_) => ref.invalidateSelf());
    ref.onDispose(sub.cancel);
    return service.fetchVendor(key.$2);
  });
}

final vendorProvider = _VendorFamily();

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------

/// Cliente Spoolman da Mobileraker.
///
/// Conversa com o servidor Spoolman **através do proxy JSON-RPC do Moonraker**
/// (`server.spoolman.proxy`) — arquitetura extraída do APK oficial 2.9.14.
/// O carretel ativo é gerenciado pelos métodos `server.spoolman.get_spool_id`
/// / `server.spoolman.post_spool_id` e pela notificação
/// `notify_active_spool_set`.
class SpoolmanService {
  SpoolmanService(
    this._ref,
    this.machineUUID, {
    required JsonRpcClient jsonRpcClient,
    required SpoolRepository spoolRepository,
    required FilamentRepository filamentRepository,
    required VendorRepository vendorRepository,
  })  : _jsonRpcClient = jsonRpcClient,
        _spoolRepository = spoolRepository,
        _filamentRepository = filamentRepository,
        _vendorRepository = vendorRepository {
    _jsonRpcClient.addMethodListener(_onActiveSpoolChanged, 'notify_active_spool_set');
    _clientStateSubscription = _jsonRpcClient.stateStream.listen(_onClientStateChanged);
    _activeSpoolTimer = Timer.periodic(const Duration(seconds: 30), (_) => _refreshActiveSpool());
    if (_jsonRpcClient.curState == ClientState.connected) {
      _refreshCurrency();
      _refreshActiveSpool();
    }
    _ref.onDispose(_dispose);
  }

  static const int defaultPageSize = 20;

  /// Enviada pelo app oficial para links/QR codes do Spoolman
  /// (`web+spoolman:s-<id>`).
  static final RegExp qrCodeRegEx = RegExp(r'^web\+spoolman:s-(?<id>[0-9]+)$');

  final Ref _ref;
  final String machineUUID;
  final JsonRpcClient _jsonRpcClient;
  final SpoolRepository _spoolRepository;
  final FilamentRepository _filamentRepository;
  final VendorRepository _vendorRepository;

  final StreamController<void> _changeController = StreamController<void>.broadcast();
  final StreamController<GetSpool?> _activeSpoolController = StreamController<GetSpool?>.broadcast();
  late final StreamSubscription<ClientState> _clientStateSubscription;
  late final Timer _activeSpoolTimer;

  String _currency = 'USD';
  GetSpool? _activeSpool;

  String get logPrefix => '[SpoolmanService($machineUUID)]';

  /// Moeda configurada no servidor Spoolman (padrão `USD`).
  String get currency => _currency;

  /// Eventos de mudança locais (usado pelos providers para invalidar).
  Stream<void> get changes => _changeController.stream;

  GetSpool? get activeSpool => _activeSpool;

  /// Carretel ativo (repassa o estado atual logo ao escutar).
  Stream<GetSpool?> get activeSpoolStream async* {
    yield _activeSpool;
    yield* _activeSpoolController.stream;
  }

  void _notifyChange() {
    if (!_changeController.isClosed) _changeController.add(null);
  }

  // -- Listagens ------------------------------------------------------------

  Future<PaginationResult<GetSpool>> spoolList({int? page, int? pageSize, SpoolmanFilter? filters}) async {
    talker.debug('$logPrefix Trying to get spool list (pageSize: $pageSize, page: $page)...');
    return _spoolRepository.paginated(page: page, pageSize: pageSize ?? defaultPageSize, filters: filters);
  }

  Future<PaginationResult<GetFilament>> filamentList({int? page, int? pageSize, SpoolmanFilter? filters}) async {
    talker.debug('$logPrefix Trying to get filament list...');
    return _filamentRepository.paginated(page: page, pageSize: pageSize ?? defaultPageSize, filters: filters);
  }

  Future<PaginationResult<GetVendor>> vendorList({int? page, int? pageSize, SpoolmanFilter? filters}) async {
    talker.debug('$logPrefix Trying to get vendor list...');
    return _vendorRepository.paginated(page: page, pageSize: pageSize ?? defaultPageSize, filters: filters);
  }

  Future<GetSpool?> fetchSpool(int id) async {
    talker.debug('$logPrefix Trying to get spool $id...');
    return _spoolRepository.readSpool(id);
  }

  Future<GetFilament?> fetchFilament(int id) async {
    talker.debug('$logPrefix Trying to get filament $id...');
    return _filamentRepository.readFilament(id);
  }

  Future<GetVendor?> fetchVendor(int id) async {
    talker.debug('$logPrefix Trying to get vendor $id...');
    return _vendorRepository.readVendor(id);
  }

  // -- Vendors --------------------------------------------------------------

  Future<GetVendor> createVendor(CreateVendor dto) async {
    final vendor = await _vendorRepository.createVendor(dto);
    _notifyChange();
    return vendor;
  }

  Future<GetVendor> updateVendor(UpdateVendor dto) async {
    final vendor = await _vendorRepository.updateVendor(dto);
    _notifyChange();
    return vendor;
  }

  Future<void> deleteVendor(GetVendor vendor) async {
    await _vendorRepository.delete(vendor.id);
    _notifyChange();
  }

  // -- Filaments ------------------------------------------------------------

  Future<GetFilament> createFilament(CreateFilament dto) async {
    final filament = await _filamentRepository.createFilament(dto);
    _notifyChange();
    return filament;
  }

  Future<GetFilament> updateFilament(UpdateFilament dto) async {
    final filament = await _filamentRepository.updateFilament(dto);
    _notifyChange();
    return filament;
  }

  Future<void> deleteFilament(GetFilament filament) async {
    await _filamentRepository.delete(filament.id);
    _notifyChange();
  }

  // -- Spools ---------------------------------------------------------------

  Future<GetSpool> createSpool(CreateSpool dto) async {
    final spool = await _spoolRepository.createSpool(dto);
    _notifyChange();
    return spool;
  }

  Future<GetSpool> updateSpool(UpdateSpool dto) async {
    final spool = await _spoolRepository.updateSpool(dto);
    if (_activeSpool?.id == spool.id) _emitActiveSpool(spool);
    _notifyChange();
    return spool;
  }

  Future<void> deleteSpool(GetSpool spool) async {
    await _spoolRepository.delete(spool.id);
    if (_activeSpool?.id == spool.id) _emitActiveSpool(null);
    _notifyChange();
  }

  Future<void> setActiveSpool(GetSpool spool) async {
    talker.debug('$logPrefix Trying to set active spool to ${spool.id}');
    await _jsonRpcClient.sendJRpcMethod('server.spoolman.post_spool_id', params: {'spool_id': spool.id});
    _emitActiveSpool(spool);
    _notifyChange();
  }

  Future<void> clearActiveSpool() async {
    talker.debug('$logPrefix Trying to clear active spool...');
    await _jsonRpcClient.sendJRpcMethod('server.spoolman.post_spool_id', params: {'spool_id': null});
    _emitActiveSpool(null);
    _notifyChange();
  }

  Future<void> archiveSpool(GetSpool spool, [bool archive = true]) async {
    talker.debug('$logPrefix Trying to archive spool ${spool.id}...');
    await _spoolRepository.updateSpool(UpdateSpool(id: spool.id, archived: archive));
    _notifyChange();
  }

  Future<void> adjustFilamentOnSpool({required GetSpool spool, double? length, double? weight}) async {
    talker.debug('$logPrefix Trying to consume filament for spool ${spool.id}...');
    if (length != null) {
      await _spoolRepository.consumeLength(spool.id, length);
    } else if (weight != null) {
      await _spoolRepository.consumeWeight(spool.id, weight);
    }
    if (_activeSpool?.id == spool.id) _refreshActiveSpool();
    _notifyChange();
  }

  // -- Metadados ------------------------------------------------------------

  Future<Set<String>> allLocations() async {
    talker.debug('$logPrefix Trying to get all locations...');
    final payload = await _proxyPayload('GET', '/v1/location');
    return _stringSetFrom(payload);
  }

  Future<Set<String>> allMaterials() async {
    talker.debug('$logPrefix Trying to get all materials...');
    final payload = await _proxyPayload('GET', '/v1/material');
    return _stringSetFrom(payload);
  }

  /// Definições dos campos extras configurados no servidor para a entidade.
  Future<List<GetExtraField>> getExtraFieldsFor(SpoolmanEntityType type) async {
    talker.debug('$logPrefix Trying to get extra fields for ${type.name}...');
    final payload = await _proxyPayload('GET', '/v1/field/${type.name}');
    final rawList = payload is List ? payload : const [];
    final fields = <GetExtraField>[
      for (final entry in rawList)
        if (entry is Map) GetExtraField.fromJson(Map<String, dynamic>.from(entry)),
    ];
    fields.sort((a, b) => (a.order ?? 0).compareTo(b.order ?? 0));
    return fields;
  }

  /// Moeda configurada no servidor (`GET /v1/setting/currency`).
  Future<String> getSystemCurrency() async {
    try {
      talker.debug('$logPrefix Trying to get price currency...');
      final payload = await _proxyPayload('GET', '/v1/setting/currency');
      if (payload is Map && payload['value'] != null) {
        return payload['value'].toString();
      }
    } catch (e, s) {
      talker.error('$logPrefix Error while getting spoolman setting currency', e, s);
    }
    return 'USD';
  }

  // -- Internos -------------------------------------------------------------

  /// Requests "soltos" (settings/fields/location/material) usam o mesmo
  /// transporte do repositório de carretéis.
  Future<dynamic> _proxyPayload(String method, String path, {Map<String, dynamic>? query}) async {
    final result = await _spoolRepository.proxy(method, path, query: query);
    return _spoolRepository.payload(result);
  }

  Set<String> _stringSetFrom(dynamic payload) {
    final rawList = payload is List ? payload : const [];
    return {
      for (final entry in rawList)
        if (entry is String && entry.isNotEmpty)
          entry
        else if (entry is Map && entry['name'] != null)
          entry['name'].toString(),
    };
  }

  void _onClientStateChanged(ClientState state) {
    if (state != ClientState.connected) return;
    talker.debug('$logPrefix Client connected. Refreshing spoolman state...');
    _refreshCurrency();
    _refreshActiveSpool();
  }

  Future<void> _refreshCurrency() async {
    final currency = await getSystemCurrency();
    if (currency == _currency) return;
    _currency = currency;
    _notifyChange();
  }

  Future<void> _refreshActiveSpool() async {
    try {
      final response = await _jsonRpcClient.sendJRpcMethod('server.spoolman.get_spool_id');
      final result = response.result;
      final nested = result['response'];
      final spoolId = JsonUtil.tryParseInt(
        result['spool_id'] ?? (nested is Map ? nested['spool_id'] : null),
      );
      if (spoolId == null) {
        talker.debug('$logPrefix Returned spool_id was null, no active spool set');
        _emitActiveSpool(null);
        return;
      }
      final spool = await _spoolRepository.readSpool(spoolId);
      _emitActiveSpool(spool);
    } catch (e, s) {
      talker.debug('$logPrefix Error while refreshing active spool, ignoring...', e, s);
    }
  }

  void _onActiveSpoolChanged(Map<String, dynamic> rawMessage) {
    final params = _firstParams(rawMessage);
    if (params == null) return;
    final spoolId = JsonUtil.tryParseInt(params['spool_id']);
    talker.debug('$logPrefix _onActiveSpoolChanged to: $spoolId');
    if (spoolId == null) {
      talker.debug('$logPrefix Active spool ejected');
      _emitActiveSpool(null);
      return;
    }
    _spoolRepository.readSpool(spoolId).then(_emitActiveSpool).catchError(
      (Object e, StackTrace s) => talker.error('$logPrefix Error while reading new active spool', e, s),
    );
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

  void _emitActiveSpool(GetSpool? spool) {
    if (spool?.id == _activeSpool?.id && spool?.remainingWeight == _activeSpool?.remainingWeight) return;
    _activeSpool = spool;
    if (!_activeSpoolController.isClosed) _activeSpoolController.add(spool);
  }

  void _dispose() {
    _activeSpoolTimer.cancel();
    _clientStateSubscription.cancel();
    _jsonRpcClient.removeMethodListener(_onActiveSpoolChanged, 'notify_active_spool_set');
    _changeController.close();
    _activeSpoolController.close();
  }
}
