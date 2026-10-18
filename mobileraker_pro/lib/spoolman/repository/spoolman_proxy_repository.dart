/*
 * Copyright (c) 2024-2026. Patrick Schmidt.
 * All rights reserved.
 */

import 'package:common/data/dto/pagination_result.dart';
import 'package:common/exceptions/mobileraker_exception.dart';
import 'package:common/network/json_rpc_client.dart';
import 'package:common/service/moonraker/klippy_service.dart';
import 'package:common/util/extensions/async_ext.dart';
import 'package:common/util/logger.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../misc/json_util.dart';
import '../dto/spoolman_filter.dart';

/// Erro retornado pelo proxy Spoolman do Moonraker.
class MoonrakerSpoolmanProxyException implements Exception {
  const MoonrakerSpoolmanProxyException(this.message, {this.error, this.statusCode});

  final String message;
  final String? error;
  final int? statusCode;

  @override
  String toString() =>
      'MoonrakerSpoolmanProxyException(statusCode: $statusCode, error: $error, message: $message)';
}

/// Decide se o Moonraker da máquina suporta a resposta v2 do proxy Spoolman
/// (`use_v2_response`), disponível a partir do Moonraker 0.9.
///
/// Extraído da lógica do pacote PRO do APK oficial: ao instanciar um
/// repositório, ele registra "Moonraker-Response-Version: V1|V2".
bool useSpoolmanProxyV2Response(Ref ref, String machineUUID) {
  final version = ref.watch(klipperProvider(machineUUID).selectAs((data) => data.moonrakerVersion)).value;
  return (version?.compareTo(0, 9, 0, 0) ?? 1) >= 0;
}

/// Base dos repositórios Spoolman que conversam com o servidor através do
/// proxy JSON-RPC do Moonraker (`server.spoolman.proxy`).
///
/// Contrato extraído do APK oficial (mobileraker 2.9.14):
/// - `GET    /v1/<path>`         — listar (com `offset`/`limit`/filtros)
/// - `GET    /v1/<path>/<id>`    — ler um item (404 => `null`)
/// - `POST   /v1/<path>`         — criar
/// - `PATCH  /v1/<path>/<id>`    — atualizar parcialmente
/// - `DELETE /v1/<path>/<id>`    — remover
/// - Parâmetros: `use_v2_response`, `request_method`, `path`, `query`, `body`
/// - Paginação: total lido do header `X-Total-Count` da resposta.
abstract class SpoolmanProxyRepository<G> {
  SpoolmanProxyRepository(this._jsonRpcClient, {required this.useV2Response});

  static const String basePath = '/v1/';
  static const int defaultPageSize = 20;

  final JsonRpcClient _jsonRpcClient;
  final bool useV2Response;

  /// Segmento da entidade na API do Spoolman (`spool`, `filament`, `vendor`).
  String get path;

  G fromJson(Map<String, dynamic> json);

  String get logPrefix => '[SpoolmanProxyRepository<$G>($path)]';

  void _validateClient() {
    if (_jsonRpcClient.curState != ClientState.connected) {
      throw MobilerakerException('JsonRpcClient is not connected. Target-URL: ${_jsonRpcClient.uri}');
    }
  }

  /// Executa um request através do proxy e devolve o envelope completo.
  Future<Map<String, dynamic>> proxy(
    String requestMethod,
    String requestPath, {
    Map<String, dynamic>? query,
    Map<String, dynamic>? body,
  }) async {
    _validateClient();
    final params = <String, dynamic>{
      if (useV2Response) 'use_v2_response': true,
      'request_method': requestMethod,
      'path': requestPath,
      if (query != null && query.isNotEmpty) 'query': _buildQuery(query),
      if (body != null) 'body': body,
    };
    talker.debug('$logPrefix Proxying $requestMethod $requestPath (query: $query)');
    final response = await _jsonRpcClient.sendJRpcMethod('server.spoolman.proxy', params: params);
    return _extractResultJson(response.result);
  }

  /// Valida o envelope e lança [MoonrakerSpoolmanProxyException] em erro.
  ///
  /// Chaves do envelope (evidenciadas no APK): `error`, `response`,
  /// `response_headers`, `list`, `status_code`, `message`.
  Map<String, dynamic> _extractResultJson(Map<String, dynamic> result) {
    final error = result['error'];
    if (error is Map) {
      throw MoonrakerSpoolmanProxyException(
        JsonUtil.tryParseString(error['message']) ?? JsonUtil.tryParseString(result['message']) ?? 'Unknown error',
        error: JsonUtil.tryParseString(error['error']) ?? JsonUtil.tryParseString(result['error']),
        statusCode: JsonUtil.tryParseInt(result['status_code']),
      );
    }
    return result;
  }

  /// Extrai o payload útil do envelope (v1 e v2).
  dynamic payload(Map<String, dynamic> result) {
    final response = result['response'];
    if (response != null) return response;
    final list = result['list'];
    if (list != null) return list;
    return result;
  }

  static String _buildQuery(Map<String, dynamic> values) {
    return values.entries.map((e) {
      final value = e.value;
      final raw = value is Iterable ? value.join(',') : '$value';
      return '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(raw)}';
    }).join('&');
  }

  // -- CRUD ------------------------------------------------------------------

  Future<G?> read(int id) async {
    try {
      final result = await proxy('GET', '$basePath$path/$id');
      final data = payload(result);
      if (data is! Map) return null;
      return fromJson(Map<String, dynamic>.from(data));
    } on MoonrakerSpoolmanProxyException catch (e, s) {
      if (e.statusCode == 404) {
        talker.debug('$logPrefix No $path found on server with id $id');
        return null;
      }
      talker.error('$logPrefix Error while reading $path with id $id', e, s);
      rethrow;
    }
  }

  Future<PaginationResult<G>> paginated({int? page, int? pageSize, SpoolmanFilter? filters}) async {
    final effectivePage = page ?? 0;
    final effectivePageSize = pageSize ?? defaultPageSize;
    final query = <String, dynamic>{
      'offset': effectivePage * effectivePageSize,
      'limit': effectivePageSize,
      ...?filters?.filters,
    };
    try {
      final result = await proxy('GET', '$basePath$path', query: query);
      final data = payload(result);
      final rawItems = data is List ? data : const [];
      final items = <G>[
        for (final entry in rawItems)
          if (entry is Map) fromJson(Map<String, dynamic>.from(entry)),
      ];
      final headers = result['response_headers'];
      final totalHeader = headers is Map ? headers['X-Total-Count'] : null;
      final total = int.tryParse('$totalHeader') ?? items.length;
      talker.debug('$logPrefix Read ${items.length} $path from server for page $effectivePage (total: $total)');
      return PaginationResult(items, total, effectivePage, effectivePageSize);
    } on MoonrakerSpoolmanProxyException catch (e, s) {
      talker.error('$logPrefix Error while reading all $path from server', e, s);
      rethrow;
    }
  }

  Future<G> create(Map<String, dynamic> body) async {
    try {
      final result = await proxy('POST', '$basePath$path', body: body);
      final data = payload(result);
      if (data is! Map) {
        throw const MoonrakerSpoolmanProxyException('Unexpected response while creating entity');
      }
      final created = fromJson(Map<String, dynamic>.from(data));
      talker.debug('$logPrefix Created $path on server');
      return created;
    } on MoonrakerSpoolmanProxyException catch (e, s) {
      talker.error('$logPrefix Error while creating $path', e, s);
      rethrow;
    }
  }

  Future<G> update(int id, Map<String, dynamic> body) async {
    try {
      talker.debug('$logPrefix Sending update request with params: $body');
      final result = await proxy('PATCH', '$basePath$path/$id', body: body);
      final data = payload(result);
      if (data is! Map) {
        throw const MoonrakerSpoolmanProxyException('Unexpected response while updating entity');
      }
      final updated = fromJson(Map<String, dynamic>.from(data));
      talker.debug('$logPrefix Updated $path on server with id $id');
      return updated;
    } on MoonrakerSpoolmanProxyException catch (e, s) {
      talker.error('$logPrefix Error while updating $path with id $id', e, s);
      rethrow;
    }
  }

  Future<void> delete(int id) async {
    try {
      await proxy('DELETE', '$basePath$path/$id');
      talker.debug('$logPrefix Deleted $path on server with id $id');
    } on MoonrakerSpoolmanProxyException catch (e, s) {
      if (e.statusCode == 404) {
        talker.debug('$logPrefix No $path found on server with id $id');
        return;
      }
      talker.error('$logPrefix Error while deleting $path with id $id', e, s);
      rethrow;
    }
  }
}
