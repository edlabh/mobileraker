/*
 * Copyright (c) 2024-2026. Patrick Schmidt.
 * All rights reserved.
 */

import 'package:common/data/dto/pagination_result.dart';
import 'package:common/exceptions/mobileraker_exception.dart';
import 'package:common/network/json_rpc_client.dart';
import 'package:common/service/moonraker/klippy_service.dart';
import 'package:common/util/extensions/async_ext.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../dto/spoolman_filter.dart';

/// Decide se o Moonraker da máquina suporta a resposta v2 do proxy Spoolman
/// (`use_v2_response`), disponível a partir do Moonraker 0.9.
///
/// Extraído da lógica do pacote PRO do APK oficial: ao instanciar um
/// repositório, ele registra "Moonraker-Response-Version: V1|V2".
bool useSpoolmanProxyV2Response(Ref ref, String machineUUID) {
  final version = ref.watch(klipperProvider(machineUUID).selectAs((data) => data.moonrakerVersion)).value;
  return (version?.compareTo(0, 9, 0, 0) ?? 1) >= 0;
}

/// Contrato base dos repositórios Spoolman que conversam com o servidor
/// através do proxy JSON-RPC do Moonraker (`server.spoolman.proxy`).
///
/// Erros do proxy são reportados como
/// [MoonrakerSpoolmanProxyException] (definida em `common`).
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

  /// Cliente JSON-RPC do Moonraker (acessível às implementações).
  JsonRpcClient get jsonRpcClient => _jsonRpcClient;

  /// Segmento da entidade na API do Spoolman (`spool`, `filament`, `vendor`).
  String get path;

  G fromJson(Map<String, dynamic> json);

  String get logPrefix => '[SpoolmanProxyRepository<$G>($path)]';

  // -- Implementado por [SpoolmanProxyRepositoryImpl] ------------------------

  /// Executa um request através do proxy e devolve o envelope completo.
  Future<Map<String, dynamic>> proxy(
    String requestMethod,
    String requestPath, {
    Map<String, dynamic>? query,
    Map<String, dynamic>? body,
  });

  /// Extrai o payload útil do envelope (v1 e v2).
  dynamic payload(Map<String, dynamic> result);

  /// Lê uma entidade pelo id (404 => `null`).
  Future<G?> read(int id);

  /// Lista paginada da entidade.
  Future<PaginationResult<G>> paginated({int? page, int? pageSize, SpoolmanFilter? filters});

  /// Cria a entidade.
  Future<G> create(Map<String, dynamic> body);

  /// Atualiza parcialmente a entidade.
  Future<G> update(int id, Map<String, dynamic> body);

  /// Remove a entidade.
  Future<void> delete(int id);
}
