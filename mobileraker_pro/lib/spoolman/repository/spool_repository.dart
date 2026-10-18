/*
 * Copyright (c) 2024-2026. Patrick Schmidt.
 * All rights reserved.
 */

import 'package:common/network/jrpc_client_provider.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../dto/create_spool.dart';
import '../dto/get_spool.dart';
import '../dto/update_spool.dart';
import 'spool_repository_impl.dart';
import 'spoolman_proxy_repository.dart';

/// Contrato do repositório de carretéis do Spoolman.
abstract class SpoolRepository extends SpoolmanProxyRepository<GetSpool> {
  SpoolRepository(super.jsonRpcClient, {required super.useV2Response});

  Future<GetSpool?> readSpool(int id);

  Future<GetSpool> createSpool(CreateSpool dto);

  Future<GetSpool> updateSpool(UpdateSpool dto);

  Future<GetSpool> consumeLength(int id, double length);

  Future<GetSpool> consumeWeight(int id, double weight);
}

final spoolRepositoryProvider = Provider.family<SpoolRepository, String>((ref, machineUUID) {
  return SpoolRepositoryImpl(
    ref.watch(jrpcClientProvider(machineUUID)),
    useV2Response: useSpoolmanProxyV2Response(ref, machineUUID),
  );
});
