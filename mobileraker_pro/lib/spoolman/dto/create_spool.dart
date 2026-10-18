/*
 * Copyright (c) 2024-2026. Patrick Schmidt.
 * All rights reserved.
 */

import 'get_filament.dart';

/// Dados para criar um carretel (spool) no Spoolman.
class CreateSpool {
  const CreateSpool({
    this.firstUsed,
    this.lastUsed,
    this.filament,
    this.price,
    this.initialWeight,
    this.remainingWeight,
    this.spoolWeight,
    this.usedWeight,
    this.location,
    this.lotNr,
    this.comment,
    this.extra,
  });

  final DateTime? firstUsed;
  final DateTime? lastUsed;
  final GetFilament? filament;
  final double? price;
  final double? initialWeight;
  final double? remainingWeight;
  final double? spoolWeight;
  final double? usedWeight;
  final String? location;
  final String? lotNr;
  final String? comment;
  final Map<String, dynamic>? extra;

  /// Payload de criação — chaves extraídas do APK oficial.
  ///
  /// Campos nulos são omitidos (o Spoolman interpreta chaves ausentes como
  /// "não informado"; enviar `null` explicitamente limparia o valor).
  Map<String, dynamic> toJson() {
    return {
      if (filament != null) 'filament_id': filament!.id,
      if (firstUsed != null) 'first_used': firstUsed!.toIso8601String(),
      if (lastUsed != null) 'last_used': lastUsed!.toIso8601String(),
      if (price != null) 'price': price,
      if (initialWeight != null) 'initial_weight': initialWeight,
      if (remainingWeight != null) 'remaining_weight': remainingWeight,
      if (spoolWeight != null) 'spool_weight': spoolWeight,
      if (usedWeight != null) 'used_weight': usedWeight,
      if (location != null) 'location': location,
      if (lotNr != null) 'lot_nr': lotNr,
      if (comment != null) 'comment': comment,
      if (extra != null) 'extra': extra,
    };
  }

  @override
  String toString() => 'CreateSpool{filament: $filament, location: $location}';
}
