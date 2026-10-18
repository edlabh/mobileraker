/*
 * Copyright (c) 2024-2026. Patrick Schmidt.
 * All rights reserved.
 */

import 'package:common/exceptions/mobileraker_exception.dart';

import '../dto/create_spool.dart';
import '../dto/get_spool.dart';
import '../dto/update_spool.dart';
import 'spool_repository.dart';
import 'spoolman_proxy_repository_impl.dart';

/// Implementação via proxy JSON-RPC do Moonraker.
class SpoolRepositoryImpl extends SpoolmanProxyRepositoryImpl<GetSpool> implements SpoolRepository {
  SpoolRepositoryImpl(super.jsonRpcClient, {required super.useV2Response});

  @override
  String get path => 'spool';

  @override
  GetSpool fromJson(Map<String, dynamic> json) => GetSpool.fromJson(json);

  @override
  Future<GetSpool?> readSpool(int id) => read(id);

  @override
  Future<GetSpool> createSpool(CreateSpool dto) => create(dto.toJson());

  @override
  Future<GetSpool> updateSpool(UpdateSpool dto) => update(dto.id, dto.toJson());

  @override
  Future<GetSpool> consumeLength(int id, double length) => _consume(id, length: length);

  @override
  Future<GetSpool> consumeWeight(int id, double weight) => _consume(id, weight: weight);

  /// `PUT /v1/spool/<id>/use` com `use_length` (mm) ou `use_weight` (g).
  Future<GetSpool> _consume(int id, {double? length, double? weight}) async {
    if (length == null && weight == null) {
      throw ArgumentError('Specify either a length or a weight, not both.');
    }
    final body = <String, dynamic>{
      if (weight != null) 'use_weight': weight,
      if (length != null) 'use_length': length,
    };
    final result = await proxy('PUT', '/v1/$path/$id/use', body: body);
    final data = payload(result);
    if (data is Map && data['id'] != null) {
      return fromJson(Map<String, dynamic>.from(data));
    }
    // Alguns servidores respondem vazio após consumir; relê o carretel.
    final reread = await read(id);
    if (reread != null) return reread;
    throw MoonrakerSpoolmanProxyException(-1, 'Could not read spool after consuming filament');
  }
}
