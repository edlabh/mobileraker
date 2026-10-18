/*
 * Copyright (c) 2024-2026. Patrick Schmidt.
 * All rights reserved.
 */

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../spoolman/dto/get_filament.dart';

extension UiFilament on GetFilament {
  /// Cor do filamento a partir do `colorHex` (com ou sem `#`, 6 ou 8 dígitos).
  Color? get color {
    final hex = colorHex;
    if (hex == null || hex.isEmpty) return null;
    final normalized = hex.replaceFirst('#', '');
    final value = int.tryParse(normalized, radix: 16);
    if (value == null) return null;
    return Color(normalized.length <= 6 ? 0xFF000000 | value : value);
  }

  /// Nome de exibição com detalhes (material, fornecedor e cor).
  String displayNameWithDetails(NumberFormat numberFormat) {
    final buffer = StringBuffer();
    buffer.write(name?.isNotEmpty == true ? name! : 'Filamento #$id');
    if (material?.isNotEmpty == true) buffer.write(' · $material');
    if (vendor != null && vendor!.name.isNotEmpty) buffer.write(' · ${vendor!.name}');
    if (colorHex?.isNotEmpty == true) buffer.write(' · #$colorHex');
    return buffer.toString();
  }
}
