/*
 * Copyright (c) 2024-2026. Patrick Schmidt.
 * All rights reserved.
 */

import '../dto/create_vendor.dart';
import '../dto/get_vendor.dart';
import '../dto/update_vendor.dart';
import 'spoolman_proxy_repository_impl.dart';
import 'vendor_repository.dart';

/// Implementação via proxy JSON-RPC do Moonraker.
class VendorRepositoryImpl extends SpoolmanProxyRepositoryImpl<GetVendor>
    implements VendorRepository {
  VendorRepositoryImpl(super.jsonRpcClient, {required super.useV2Response});

  @override
  String get path => 'vendor';

  @override
  GetVendor fromJson(Map<String, dynamic> json) => GetVendor.fromJson(json);

  @override
  Future<GetVendor?> readVendor(int id) => read(id);

  @override
  Future<GetVendor> createVendor(CreateVendor dto) => create(dto.toJson());

  @override
  Future<GetVendor> updateVendor(UpdateVendor dto) => update(dto.id, dto.toJson());
}
