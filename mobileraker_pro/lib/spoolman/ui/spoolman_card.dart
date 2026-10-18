/*
 * Copyright (c) 2024-2026. Patrick Schmidt.
 * All rights reserved.
 */

import 'package:common/service/ui/bottom_sheet_service_interface.dart';
import 'package:common/ui/components/spool_widget.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shimmer/shimmer.dart';

import '../../service/ui/pro_routes.dart';
import '../../service/ui/pro_sheet_type.dart';
import '../dto/get_spool.dart';
import '../service/spoolman_service.dart';

/// Card de dashboard do Spoolman.
///
/// Mostra o carretel ativo (com o uso e o restante de filamento) e permite
/// selecionar um carretel diretamente pelo card.
class SpoolmanCard extends ConsumerWidget {
  const SpoolmanCard({super.key, required this.machineUUID});

  static const String previewUUID = 'preview';

  final String machineUUID;

  static Widget preview() => const SpoolmanCard(machineUUID: previewUUID);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPreview = machineUUID == previewUUID;
    final activeSpoolAsync = isPreview ? null : ref.watch(activeSpoolProvider(machineUUID));

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'components.dashboard_cards.spoolman_card.title'.tr(),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (isPreview)
              const _NoSpoolBody(machineUUID: null)
            else
              switch (activeSpoolAsync!) {
                AsyncData(:final value) => value == null
                    ? _NoSpoolBody(machineUUID: machineUUID)
                    : _ActiveSpoolBody(machineUUID: machineUUID, spool: value),
                AsyncError(:final error) => _ErrorBody(error: error),
                _ => const SpoolmanCardLoading(),
              },
          ],
        ),
      ),
    );
  }
}

/// Estado de carregamento do card (shimmer).
class SpoolmanCardLoading extends StatelessWidget {
  const SpoolmanCardLoading({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = theme.colorScheme.surfaceContainerHighest;
    final highlight = theme.colorScheme.surfaceContainerLow;
    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: Row(
        children: [
          CircleAvatar(backgroundColor: base, radius: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 12,
                  width: 140,
                  decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(6)),
                ),
                const SizedBox(height: 6),
                Container(
                  height: 10,
                  width: 90,
                  decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(5)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NoSpoolBody extends ConsumerWidget {
  const _NoSpoolBody({required this.machineUUID});

  final String? machineUUID;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uuid = machineUUID;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('components.dashboard_cards.spoolman_card.no_spool'.tr()),
        if (uuid != null) ...[
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.tonalIcon(
              onPressed: () => ref.read(bottomSheetServiceProvider).show(
                    BottomSheetConfig(type: ProSheetType.selectSpoolman, data: uuid),
                  ),
              icon: const Icon(Icons.inventory_2_outlined),
              label: Text('components.dashboard_cards.spoolman_card.select_spool'.tr()),
            ),
          ),
        ],
      ],
    );
  }
}

class _ActiveSpoolBody extends StatelessWidget {
  const _ActiveSpoolBody({required this.machineUUID, required this.spool});

  final String machineUUID;
  final GetSpool spool;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filament = spool.filament;
    final used = spool.usedWeight;
    final remaining = spool.remainingWeight;
    final initial = spool.initialWeight;
    final progress =
        (initial != null && initial > 0 && remaining != null) ? (remaining / initial).clamp(0.0, 1.0) : null;

    final details = [
      if (filament.vendor != null) filament.vendor!.name,
      if (filament.material != null && filament.material!.isNotEmpty) filament.material!,
    ].join(' · ');

    final name = filament.name;
    final title = (name == null || name.isEmpty) ? '${'pages.spoolman.spool'.tr()} #${spool.id}' : name;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => context.pushNamed(
        ProRoutes.spoolman_details_spool.name,
        extra: [machineUUID, spool],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              SpoolWidget(color: filament.colorHex, height: 36),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
                    ),
                    if (details.isNotEmpty)
                      Text(
                        details,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (progress != null) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(value: progress, minHeight: 6),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            'components.dashboard_cards.spoolman_card.used'.tr(args: ['${used.toStringAsFixed(0)} g']),
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'components.dashboard_cards.spoolman_card.provider_error_title'.tr(),
          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        Text('$error', style: theme.textTheme.bodySmall),
      ],
    );
  }
}
