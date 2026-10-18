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

enum SpoolmanListType { spools, filaments, vendors }

/// Lista paginada do Spoolman.
///
/// Stub local: renderiza os itens do store em memória do
/// [SpoolmanService] (criados via formulários durante a sessão).
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
        if (items.isEmpty) return const SpoolmanEmptyState();
        return ListView.builder(
          controller: scrollController,
          physics: physics,
          padding: padding ?? EdgeInsets.zero,
          itemCount: items.length,
          itemBuilder: (context, index) => SpoolmanEntryTile(dto: items[index], onTap: onEntryTap),
        );
      },
      error: (error, stackTrace) => SpoolmanMessageState(
        icon: Icons.error_outline,
        message: error.toString(),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }
}

/// Estado vazio das listagens do Spoolman.
class SpoolmanEmptyState extends StatelessWidget {
  const SpoolmanEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined, size: 48),
            SizedBox(height: 8),
            Text(
              'Nenhum item do Spoolman ainda.',
              textAlign: TextAlign.center,
            ),
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

/// Tile de uma entidade do Spoolman.
class SpoolmanEntryTile extends StatelessWidget {
  const SpoolmanEntryTile({super.key, required this.dto, this.onTap});

  final Object dto;
  final void Function(SpoolmanIdentifiableDtoMixin dto)? onTap;

  @override
  Widget build(BuildContext context) {
    final (icon, title, subtitle) = switch (dto) {
      GetSpool spool => (
          Icons.inventory_2_outlined,
          'Carretel #${spool.id}',
          filamentLabel(spool.filament),
        ),
      GetFilament filament => (
          Icons.circle_outlined,
          filamentLabel(filament) ?? 'Filamento #${filament.id}',
          filament.vendor?.name,
        ),
      GetVendor vendor => (Icons.factory_outlined, vendor.name, null),
      _ => (Icons.help_outline, dto.toString(), null),
    };
    final tappable = onTap != null && dto is SpoolmanIdentifiableDtoMixin;
    return ListTile(
      leading: Icon(icon),
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: subtitle == null
          ? null
          : Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
      onTap: tappable ? () => onTap!(dto as SpoolmanIdentifiableDtoMixin) : null,
    );
  }
}

String? filamentLabel(GetFilament filament) {
  final name = filament.name;
  final material = filament.material;
  if (name == null || name.isEmpty) return material;
  if (material == null || material.isEmpty) return name;
  return '$name · $material';
}
