/*
 * Copyright (c) 2024-2026. Patrick Schmidt.
 * All rights reserved.
 */

import 'package:common/network/jrpc_client_provider.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../dto/create_vendor.dart';
import '../dto/get_vendor.dart';
import '../dto/update_vendor.dart';
import 'spoolman_proxy_repository.dart';
import 'vendor_repository_impl.dart';

/// Contrato do repositório de fornecedores do Spoolman.
abstract class VendorRepository extends SpoolmanProxyRepository<GetVendor> {
  VendorRepository(super.jsonRpcClient, {required super.useV2Response});

  Future<GetVendor?> readVendor(int id);

  Future<GetVendor> createVendor(CreateVendor dto);

  Future<GetVendor> updateVendor(UpdateVendor dto);
}

final vendorRepositoryProvider = Provider.family<VendorRepository, String>((ref, machineUUID) {
  return VendorRepositoryImpl(
    ref.watch(jrpcClientProvider(machineUUID)),
    useV2Response: useSpoolmanProxyV2Response(ref, machineUUID),
  );
});
