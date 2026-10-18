/*
 * Copyright (c) 2024-2026. Patrick Schmidt.
 * All rights reserved.
 */

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../dto/get_extra_field.dart';
import '../dto/spoolman_entity_type_enum.dart';
import '../service/spoolman_service.dart';
import 'property_with_title.dart';

/// Exibe os campos extras de uma entidade do Spoolman.
///
/// Os rótulos e unidades vêm das definições configuradas no servidor
/// ([spoolmanExtraFieldsProvider]); valores sem definição usam a própria
/// chave como rótulo.
class ExtraFieldsView extends ConsumerWidget {
  const ExtraFieldsView({
    super.key,
    required this.machineUUID,
    required this.type,
    this.extra,
  });

  final String machineUUID;
  final SpoolmanEntityType type;
  final Map<String, dynamic>? extra;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final values = extra;
    if (values == null || values.isEmpty) return const SizedBox.shrink();
    final definitions = ref.watch(spoolmanExtraFieldsProvider(machineUUID, type)).value ?? const <GetExtraField>[];
    final byKey = {for (final field in definitions) field.key: field};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final entry in values.entries)
          PropertyWithTitle.text(
            title: _title(byKey[entry.key], entry.key),
            property: _format(entry.value),
          ),
      ],
    );
  }

  String _title(GetExtraField? field, String key) {
    final name = field?.name ?? key;
    final unit = field?.unit;
    return (unit == null || unit.isEmpty) ? name : '$name ($unit)';
  }

  String _format(dynamic value) {
    if (value == null) return '—';
    if (value is bool) return value ? 'true' : 'false';
    if (value is Iterable) return value.join(', ');
    return value.toString();
  }
}
