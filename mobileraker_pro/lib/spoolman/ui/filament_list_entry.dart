/*
 * Copyright (c) 2024-2026. Patrick Schmidt.
 * All rights reserved.
 */

import 'package:common/ui/components/spool_widget.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../dto/get_filament.dart';

/// Item de um filamento nas listagens do Spoolman.
class FilamentListEntry extends StatelessWidget {
  const FilamentListEntry({super.key, required this.filament, this.onTap});

  final GetFilament filament;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final name = filament.name;
    final title = (name == null || name.isEmpty)
        ? '${'pages.spoolman.filament'.tr()} #${filament.id}'
        : name;

    final details = [
      if (filament.vendor != null) filament.vendor!.name,
      if (filament.material != null && filament.material!.isNotEmpty) filament.material!,
    ].join(' · ');

    final weight = filament.weight;

    return ListTile(
      leading: SpoolWidget(color: filament.colorHex, height: 40),
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: details.isEmpty
          ? null
          : Text(details, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: weight == null
          ? null
          : Text('${weight.toStringAsFixed(0)} g'),
      onTap: onTap,
    );
  }
}
