/*
 * Copyright (c) 2024-2026. Patrick Schmidt.
 * All rights reserved.
 */

import '../dto/create_filament.dart';
import '../dto/get_filament.dart';
import '../dto/update_filament.dart';
import 'filament_repository.dart';

/// Implementação via proxy JSON-RPC do Moonraker.
class FilamentRepositoryImpl extends FilamentRepository {
  FilamentRepositoryImpl(super.jsonRpcClient, {required super.useV2Response});

  @override
  String get path => 'filament';

  @override
  GetFilament fromJson(Map<String, dynamic> json) => GetFilament.fromJson(json);

  @override
  Future<GetFilament?> readFilament(int id) => read(id);

  @override
  Future<GetFilament> createFilament(CreateFilament dto) => create(dto.toJson());

  @override
  Future<GetFilament> updateFilament(UpdateFilament dto) => update(dto.id, dto.toJson());
}
