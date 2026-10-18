/*
 * Copyright (c) 2024-2026. Patrick Schmidt.
 * All rights reserved.
 */

import 'package:common/network/jrpc_client_provider.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../dto/create_filament.dart';
import '../dto/get_filament.dart';
import '../dto/update_filament.dart';
import 'filament_repository_impl.dart';
import 'spoolman_proxy_repository.dart';

/// Contrato do repositório de filamentos do Spoolman.
abstract class FilamentRepository extends SpoolmanProxyRepository<GetFilament> {
  FilamentRepository(super.jsonRpcClient, {required super.useV2Response});

  Future<GetFilament?> readFilament(int id);

  Future<GetFilament> createFilament(CreateFilament dto);

  Future<GetFilament> updateFilament(UpdateFilament dto);
}

final filamentRepositoryProvider = Provider.family<FilamentRepository, String>((ref, machineUUID) {
  return FilamentRepositoryImpl(
    ref.watch(jrpcClientProvider(machineUUID)),
    useV2Response: useSpoolmanProxyV2Response(ref, machineUUID),
  );
});
