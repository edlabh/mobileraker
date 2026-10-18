/*
 * Copyright (c) 2024-2026. Patrick Schmidt.
 * All rights reserved.
 */

import 'package:common/data/dto/pagination_result.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../dto/get_filament.dart';
import '../dto/get_spool.dart';
import '../dto/get_vendor.dart';
import '../dto/spoolman_dto_mixin.dart';
import '../dto/spoolman_filter.dart';
import '../service/spoolman_service.dart';
import 'filament_list_entry.dart';
import 'spool_list_entry.dart';
import 'spool_list_entry_shimmer.dart';
import 'spoolman_scroll_pagination.dart';
import 'vendor_list_entry.dart';
import 'vendor_list_entry_shimmer.dart';

/// Lista estática (não paginada visualmente) do Spoolman, usada dentro de
/// páginas de detalhe.
class SpoolmanStaticPagination extends ConsumerWidget {
  const SpoolmanStaticPagination({
    super.key,
    required this.machineUUID,
    required this.type,
    this.initialCount = 5,
    this.filters,
    this.exclude,
    this.onEntryTap,
  });

  final String machineUUID;
  final SpoolmanListType type;
  final int initialCount;
  final SpoolmanFilter? filters;
  final SpoolmanIdentifiableDtoMixin? exclude;
  final void Function(SpoolmanIdentifiableDtoMixin dto)? onEntryTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Object> async = switch (type) {
      SpoolmanListType.spools =>
        ref.watch(spoolListProvider(machineUUID, pageSize: initialCount, filters: filters)),
      SpoolmanListType.filaments =>
        ref.watch(filamentListProvider(machineUUID, pageSize: initialCount, filters: filters)),
      SpoolmanListType.vendors =>
        ref.watch(vendorListProvider(machineUUID, pageSize: initialCount, filters: filters)),
    };

    return async.when(
      data: (result) {
        var items = (result as PaginationResult<dynamic>).items;
        final excluded = exclude;
        if (excluded != null) {
          items = items
              .where((e) =>
                  !(e.runtimeType == excluded.runtimeType &&
                      e is SpoolmanIdentifiableDtoMixin &&
                      e.id == excluded.id))
              .toList(growable: false);
        }
        if (items.isEmpty) return const SizedBox.shrink();
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final dto in items) _buildEntry(dto),
          ],
        );
      },
      error: (error, stackTrace) => const SizedBox.shrink(),
      loading: () => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < initialCount; i++) _buildShimmer(),
        ],
      ),
    );
  }

  Widget _buildEntry(Object dto) {
    final onTap = (onEntryTap == null || dto is! SpoolmanIdentifiableDtoMixin)
        ? null
        : () => onEntryTap!(dto);
    return switch (dto) {
      GetSpool spool => SpoolListEntry(spool: spool, onTap: onTap),
      GetFilament filament => FilamentListEntry(filament: filament, onTap: onTap),
      GetVendor vendor => VendorListEntry(vendor: vendor, onTap: onTap),
      _ => const SizedBox.shrink(),
    };
  }

  Widget _buildShimmer() => switch (type) {
        SpoolmanListType.vendors => const VendorListEntryShimmer(),
        _ => const SpoolListEntryShimmer(),
      };
}
