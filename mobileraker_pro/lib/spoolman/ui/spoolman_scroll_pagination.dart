/*
 * Copyright (c) 2024-2026. Patrick Schmidt.
 * All rights reserved.
 */

import 'package:common/data/dto/pagination_result.dart';
import 'package:easy_localization/easy_localization.dart';
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
import 'vendor_list_entry.dart';
import 'vendor_list_entry_shimmer.dart';

enum SpoolmanListType { spools, filaments, vendors }

/// Lista paginada do Spoolman (carretéis, filamentos ou fabricantes).
class SpoolmanScrollPagination extends ConsumerWidget {
  const SpoolmanScrollPagination({
    super.key,
    required this.machineUUID,
    required this.type,
    this.scrollController,
    this.physics,
    this.padding,
    this.filters,
    this.onEntryTap,
  });

  final String machineUUID;
  final SpoolmanListType type;
  final ScrollController? scrollController;
  final ScrollPhysics? physics;
  final EdgeInsets? padding;
  final SpoolmanFilter? filters;
  final void Function(SpoolmanIdentifiableDtoMixin dto)? onEntryTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Object> async = switch (type) {
      SpoolmanListType.spools => ref.watch(spoolListProvider(machineUUID, filters: filters)),
      SpoolmanListType.filaments => ref.watch(filamentListProvider(machineUUID, filters: filters)),
      SpoolmanListType.vendors => ref.watch(vendorListProvider(machineUUID, filters: filters)),
    };

    return async.when(
      data: (result) {
        final items = (result as PaginationResult<dynamic>).items;
        if (items.isEmpty) return SpoolmanEmptyState(type: type);
        return ListView.builder(
          controller: scrollController,
          physics: physics,
          padding: padding ?? EdgeInsets.zero,
          itemCount: items.length,
          itemBuilder: (context, index) => _buildEntry(items[index]),
        );
      },
      error: (error, stackTrace) => SpoolmanMessageState(
        icon: Icons.error_outline,
        message: _errorMessage(error),
      ),
      loading: () => ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: padding ?? EdgeInsets.zero,
        itemCount: 6,
        itemBuilder: (context, index) => _buildShimmer(),
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

  String _errorMessage(Object error) => switch (type) {
        SpoolmanListType.spools => 'pages.spoolman.error_loading_spools'.tr(),
        SpoolmanListType.filaments => 'pages.spoolman.error_loading_filaments'.tr(),
        SpoolmanListType.vendors => '$error',
      };
}

/// Estado vazio das listagens do Spoolman.
class SpoolmanEmptyState extends StatelessWidget {
  const SpoolmanEmptyState({super.key, this.type = SpoolmanListType.spools});

  final SpoolmanListType type;

  @override
  Widget build(BuildContext context) {
    final message = switch (type) {
      SpoolmanListType.spools => 'pages.spoolman.no_spools'.tr(),
      SpoolmanListType.filaments => 'pages.spoolman.no_filaments'.tr(),
      SpoolmanListType.vendors => 'pages.spoolman.no_vendors'.tr(),
    };
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inventory_2_outlined, size: 48),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

/// Estado de erro/mensagem das listagens do Spoolman.
class SpoolmanMessageState extends StatelessWidget {
  const SpoolmanMessageState({super.key, required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
