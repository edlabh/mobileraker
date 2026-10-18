/*
 * Copyright (c) 2024-2026. Patrick Schmidt.
 * All rights reserved.
 */

import 'package:flutter/material.dart';

import '../dto/spoolman_entity_type_enum.dart';

/// Seção de campos extras no formulário do Spoolman.
///
/// Stub local: os campos extras dependem do servidor real do Spoolman (que
/// informa quais chaves existem), então nada é renderizado além do cabeçalho.
class ExtraFieldsFormSection extends StatelessWidget {
  const ExtraFieldsFormSection({
    super.key,
    required this.machineUUID,
    required this.type,
    this.extraValues,
    this.header,
  });

  final String machineUUID;
  final SpoolmanEntityType type;
  final Map<String, dynamic>? extraValues;
  final Widget? header;

  @override
  Widget build(BuildContext context) {
    if (header == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [header!],
    );
  }
}

extension ExtractExtraFields on Map<String, dynamic> {
  /// Stub local: sem servidor Spoolman integrado não existem campos extras.
  Map<String, dynamic> extractExtraFields() => const <String, dynamic>{};
}
