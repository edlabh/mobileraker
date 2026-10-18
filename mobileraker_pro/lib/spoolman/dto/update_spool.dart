/*
 * Copyright (c) 2024-2026. Patrick Schmidt.
 * All rights reserved.
 */

import 'get_filament.dart';

/// Atualização parcial de um carretel (campos `null` = inalterados).
class UpdateSpool {
  const UpdateSpool({
    required this.id,
    this.filament,
    this.firstUsed,
    this.lastUsed,
    this.initialWeight,
    this.spoolWeight,
    this.price,
    this.usedWeight,
    this.location,
    this.lotNr,
    this.comment,
    this.archived,
    this.extra,
  });

  final int id;
  final GetFilament? filament;
  final DateTime? firstUsed;
  final DateTime? lastUsed;
  final double? initialWeight;
  final double? spoolWeight;
  final double? price;
  final double? usedWeight;
  final String? location;
  final String? lotNr;
  final String? comment;
  final bool? archived;
  final Map<String, dynamic>? extra;

  /// Payload de atualização (PATCH) — chaves extraídas do APK oficial.
  ///
  /// Campos nulos são omitidos para que o Spoolman mantenha os valores atuais.
  Map<String, dynamic> toJson() {
    return {
      if (archived != null) 'archived': archived,
      if (comment != null) 'comment': comment,
      if (extra != null) 'extra': extra,
      if (filament != null) 'filament_id': filament!.id,
      if (firstUsed != null) 'first_used': firstUsed!.toIso8601String(),
      if (initialWeight != null) 'initial_weight': initialWeight,
      if (lastUsed != null) 'last_used': lastUsed!.toIso8601String(),
      if (location != null) 'location': location,
      if (lotNr != null) 'lot_nr': lotNr,
      if (price != null) 'price': price,
      if (spoolWeight != null) 'spool_weight': spoolWeight,
      if (usedWeight != null) 'used_weight': usedWeight,
    };
  }

  @override
  String toString() => 'UpdateSpool{id: $id}';
}
