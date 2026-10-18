/*
 * Copyright (c) 2024-2026. Patrick Schmidt.
 * All rights reserved.
 */

import 'package:common/data/dto/pagination_result.dart';
import 'package:common/exceptions/mobileraker_exception.dart';
import 'package:common/network/json_rpc_client.dart';
import 'package:common/util/logger.dart';

import '../../misc/json_util.dart';
import '../dto/spoolman_filter.dart';
import 'spoolman_proxy_repository.dart';

/// Implementação compartilhada dos repositórios Spoolman via proxy JSON-RPC
/// do Moonraker (`server.spoolman.proxy`).
abstract class SpoolmanProxyRepositoryImpl<G> extends SpoolmanProxyRepository<G> {
  SpoolmanProxyRepositoryImpl(super.jsonRpcClient, {required super.useV2Response});

  void _validateClient() {
    if (jsonRpcClient.curState != ClientState.connected) {
      throw MobilerakerException('JsonRpcClient is not connected. Target-URL: ${jsonRpcClient.uri}');
    }
  }

  @override
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
    final response = await jsonRpcClient.sendJRpcMethod('server.spoolman.proxy', params: params);
    return _extractResultJson(response.result);
  }

  /// Valida o envelope e lança [MoonrakerSpoolmanProxyException] em erro.
  ///
  /// Chaves do envelope (evidenciadas no APK): `error`, `response`,
  /// `response_headers`, `list`, `status_code`, `message`.
  Map<String, dynamic> _extractResultJson(Map<String, dynamic> result) {
    final error = result['error'];
    if (error is Map) {
      final message = JsonUtil.tryParseString(error['message']) ??
          JsonUtil.tryParseString(result['message']) ??
          'Unknown error';
      final detail = JsonUtil.tryParseString(error['error']) ?? JsonUtil.tryParseString(result['error']);
      throw MoonrakerSpoolmanProxyException(
        JsonUtil.tryParseInt(result['status_code']) ?? -1,
        detail == null ? message : '$message ($detail)',
      );
    }
    return result;
  }

  @override
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

  @override
  Future<G?> read(int id) async {
    try {
      final result = await proxy('GET', '${SpoolmanProxyRepository.basePath}$path/$id');
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

  @override
  Future<PaginationResult<G>> paginated({int? page, int? pageSize, SpoolmanFilter? filters}) async {
    final effectivePage = page ?? 0;
    final effectivePageSize = pageSize ?? SpoolmanProxyRepository.defaultPageSize;
    final query = <String, dynamic>{
      'offset': effectivePage * effectivePageSize,
      'limit': effectivePageSize,
      ...?filters?.filters,
    };
    try {
      final result = await proxy('GET', '${SpoolmanProxyRepository.basePath}$path', query: query);
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

  @override
  Future<G> create(Map<String, dynamic> body) async {
    try {
      final result = await proxy('POST', '${SpoolmanProxyRepository.basePath}$path', body: body);
      final data = payload(result);
      if (data is! Map) {
        throw MoonrakerSpoolmanProxyException(-1, 'Unexpected response while creating entity');
      }
      final created = fromJson(Map<String, dynamic>.from(data));
      talker.debug('$logPrefix Created $path on server');
      return created;
    } on MoonrakerSpoolmanProxyException catch (e, s) {
      talker.error('$logPrefix Error while creating $path', e, s);
      rethrow;
    }
  }

  @override
  Future<G> update(int id, Map<String, dynamic> body) async {
    try {
      talker.debug('$logPrefix Sending update request with params: $body');
      final result = await proxy('PATCH', '${SpoolmanProxyRepository.basePath}$path/$id', body: body);
      final data = payload(result);
      if (data is! Map) {
        throw MoonrakerSpoolmanProxyException(-1, 'Unexpected response while updating entity');
      }
      final updated = fromJson(Map<String, dynamic>.from(data));
      talker.debug('$logPrefix Updated $path on server with id $id');
      return updated;
    } on MoonrakerSpoolmanProxyException catch (e, s) {
      talker.error('$logPrefix Error while updating $path with id $id', e, s);
      rethrow;
    }
  }

  @override
  Future<void> delete(int id) async {
    try {
      await proxy('DELETE', '${SpoolmanProxyRepository.basePath}$path/$id');
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
