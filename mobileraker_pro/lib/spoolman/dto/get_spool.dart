/*
 * Copyright (c) 2024-2026. Patrick Schmidt.
 * All rights reserved.
 */

import 'package:flutter/foundation.dart';

import '../../misc/json_util.dart';
import 'get_filament.dart';
import 'spoolman_dto_mixin.dart';

/// Carretel (spool) retornado pelo Spoolman.
class GetSpool implements SpoolmanIdentifiableDtoMixin {
  const GetSpool({
    required this.id,
    required this.registered,
    required this.filament,
    required this.usedWeight,
    required this.usedLength,
    this.firstUsed,
    this.lastUsed,
    this.price,
    this.initialWeight,
    this.spoolWeight,
    this.remainingWeight,
    this.remainingLength,
    this.location,
    this.lotNr,
    this.comment,
    this.archived = false,
    this.extra,
  });

  /// Reconstrói o carretel a partir do payload do Spoolman.
  ///
  /// Chaves (snake_case) extraídas do APK oficial: `id`, `registered`,
  /// `first_used`, `last_used`, `filament`, `price`, `initial_weight`,
  /// `spool_weight`, `used_weight`, `used_length`, `remaining_weight`,
  /// `remaining_length`, `location`, `lot_nr`, `comment`, `archived`, `extra`.
  factory GetSpool.fromJson(Map<String, dynamic> json) {
    final filamentJson = JsonUtil.tryParseMap(json['filament']);
    return GetSpool(
      id: JsonUtil.tryParseInt(json['id']) ?? 0,
      registered: JsonUtil.tryParseDate(json['registered']) ?? DateTime.now(),
      firstUsed: JsonUtil.tryParseDate(json['first_used']),
      lastUsed: JsonUtil.tryParseDate(json['last_used']),
      filament: filamentJson == null
          ? GetFilament(id: 0, registered: DateTime.now(), density: 0, diameter: 1.75)
          : GetFilament.fromJson(filamentJson),
      price: JsonUtil.tryParseDouble(json['price']),
      initialWeight: JsonUtil.tryParseDouble(json['initial_weight']),
      spoolWeight: JsonUtil.tryParseDouble(json['spool_weight']),
      remainingWeight: JsonUtil.tryParseDouble(json['remaining_weight']),
      usedWeight: JsonUtil.tryParseDouble(json['used_weight']) ?? 0,
      remainingLength: JsonUtil.tryParseDouble(json['remaining_length']),
      usedLength: JsonUtil.tryParseDouble(json['used_length']) ?? 0,
      location: JsonUtil.tryParseString(json['location']),
      lotNr: JsonUtil.tryParseString(json['lot_nr']),
      comment: JsonUtil.tryParseString(json['comment']),
      archived: JsonUtil.tryParseBool(json['archived']) ?? false,
      extra: JsonUtil.tryParseMap(json['extra']),
    );
  }

  @override
  final int id;
  final DateTime registered;
  final DateTime? firstUsed;
  final DateTime? lastUsed;
  final GetFilament filament;
  final double? price;
  final double? initialWeight;
  final double? spoolWeight;
  final double? remainingWeight;
  final double usedWeight;
  final double? remainingLength;
  final double usedLength;
  final String? location;
  final String? lotNr;
  final String? comment;
  final bool archived;
  final Map<String, dynamic>? extra;

  /// Fração restante do carretel (peso restante / peso inicial).
  double? get progress {
    final initial = initialWeight;
    final remaining = remainingWeight;
    if (initial == null || initial <= 0 || remaining == null) return null;
    return (remaining / initial).clamp(0.0, 1.0);
  }

  GetSpool copyWith({
    DateTime? firstUsed,
    DateTime? lastUsed,
    GetFilament? filament,
    double? price,
    double? initialWeight,
    double? spoolWeight,
    double? remainingWeight,
    double? usedWeight,
    double? remainingLength,
    double? usedLength,
    String? location,
    String? lotNr,
    String? comment,
    bool? archived,
    Map<String, dynamic>? extra,
  }) {
    return GetSpool(
      id: id,
      registered: registered,
      firstUsed: firstUsed ?? this.firstUsed,
      lastUsed: lastUsed ?? this.lastUsed,
      filament: filament ?? this.filament,
      price: price ?? this.price,
      initialWeight: initialWeight ?? this.initialWeight,
      spoolWeight: spoolWeight ?? this.spoolWeight,
      remainingWeight: remainingWeight ?? this.remainingWeight,
      usedWeight: usedWeight ?? this.usedWeight,
      remainingLength: remainingLength ?? this.remainingLength,
      usedLength: usedLength ?? this.usedLength,
      location: location ?? this.location,
      lotNr: lotNr ?? this.lotNr,
      comment: comment ?? this.comment,
      archived: archived ?? this.archived,
      extra: extra ?? this.extra,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GetSpool &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          registered == other.registered &&
          firstUsed == other.firstUsed &&
          lastUsed == other.lastUsed &&
          filament == other.filament &&
          price == other.price &&
          initialWeight == other.initialWeight &&
          spoolWeight == other.spoolWeight &&
          remainingWeight == other.remainingWeight &&
          usedWeight == other.usedWeight &&
          remainingLength == other.remainingLength &&
          usedLength == other.usedLength &&
          location == other.location &&
          lotNr == other.lotNr &&
          comment == other.comment &&
          archived == other.archived &&
          mapEquals(extra, other.extra);

  @override
  int get hashCode => Object.hash(
        id,
        registered,
        firstUsed,
        lastUsed,
        filament,
        price,
        initialWeight,
        spoolWeight,
        remainingWeight,
        usedWeight,
        remainingLength,
        usedLength,
        location,
        lotNr,
        comment,
        archived,
        extra == null ? null : Object.hashAllUnordered(extra!.entries.map((e) => Object.hash(e.key, e.value))),
      );

  @override
  String toString() => 'GetSpool{id: $id, filament: ${filament.id}, archived: $archived}';
}
