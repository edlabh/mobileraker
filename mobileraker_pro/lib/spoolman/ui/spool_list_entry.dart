/*
 * Copyright (c) 2024-2026. Patrick Schmidt.
 * All rights reserved.
 */

import 'package:common/ui/components/spool_widget.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../dto/get_spool.dart';

/// Item de um carretel nas listagens do Spoolman.
class SpoolListEntry extends StatelessWidget {
  const SpoolListEntry({super.key, required this.spool, this.onTap});

  final GetSpool spool;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final filament = spool.filament;
    final remaining = spool.remainingWeight;
    final theme = Theme.of(context);

    final name = filament.name;
    final title = (name == null || name.isEmpty)
        ? '${'pages.spoolman.spool'.tr()} #${spool.id}'
        : name;

    final details = [
      if (filament.vendor != null) filament.vendor!.name,
      if (filament.material != null && filament.material!.isNotEmpty) filament.material!,
      if (spool.location != null && spool.location!.isNotEmpty) spool.location!,
    ].join(' · ');

    return ListTile(
      leading: SpoolWidget(color: filament.colorHex, height: 40),
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: details.isEmpty
          ? null
          : Text(details, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: remaining == null
          ? null
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${remaining.toStringAsFixed(0)} g',
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
                Text(
                  'pages.spoolman.properties.remaining_weight'.tr(),
                  style: theme.textTheme.labelSmall,
                ),
              ],
            ),
      onTap: onTap,
    );
  }
}
