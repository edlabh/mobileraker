/*
 * Copyright (c) 2024-2026. Patrick Schmidt.
 * All rights reserved.
 */

import 'package:flutter/material.dart';

import '../dto/spoolman_entity_type_enum.dart';

/// Exibe os campos extras de uma entidade do Spoolman.
///
/// Stub local: renderiza os valores presentes no DTO (normalmente não há
/// nenhum, já que sem servidor não existem campos extras configurados).
class ExtraFieldsView extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final values = extra;
    if (values == null || values.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final entry in values.entries)
            Chip(label: Text('${entry.key}: ${entry.value}')),
        ],
      ),
    );
  }
}
