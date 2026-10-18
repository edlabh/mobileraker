/*
 * Copyright (c) 2024-2026. Patrick Schmidt.
 * All rights reserved.
 */

import 'package:common/data/dto/pagination_result.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../dto/spoolman_dto_mixin.dart';
import '../dto/spoolman_filter.dart';
import '../service/spoolman_service.dart';
import 'spoolman_scroll_pagination.dart';

/// Lista estática (não paginada visualmente) do Spoolman, usada dentro de
/// páginas de detalhe.
///
/// Stub local: renderiza até [initialCount] itens do store em memória.
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
            for (final dto in items)
              SpoolmanEntryTile(
                dto: dto,
                onTap: onEntryTap,
              ),
          ],
        );
      },
      error: (error, stackTrace) => const SizedBox.shrink(),
      loading: () => const SizedBox.shrink(),
    );
  }
}
