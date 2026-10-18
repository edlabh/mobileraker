/*
 * Copyright (c) 2024-2026. Patrick Schmidt.
 * All rights reserved.
 */

import 'package:flutter/foundation.dart';

import '../../misc/json_util.dart';
import 'get_vendor.dart';
import 'spoolman_dto_mixin.dart';

/// Filamento retornado pelo Spoolman.
class GetFilament implements SpoolmanIdentifiableDtoMixin {
  const GetFilament({
    required this.id,
    required this.registered,
    required this.density,
    required this.diameter,
    this.name,
    this.vendor,
    this.material,
    this.price,
    this.weight,
    this.spoolWeight,
    this.articleNumber,
    this.comment,
    this.settingsExtruderTemp,
    this.settingsBedTemp,
    this.colorHex,
    this.externalId,
    this.multiColorHexes,
    this.multiColorDirection,
    this.extra,
  });

  /// Reconstrói o filamento a partir do payload do Spoolman.
  ///
  /// Chaves (snake_case) extraídas do APK oficial: `id`, `registered`, `name`,
  /// `vendor`, `material`, `price`, `density`, `diameter`, `weight`,
  /// `spool_weight`, `article_number`, `comment`, `settings_extruder_temp`,
  /// `settings_bed_temp`, `color_hex`, `external_id`, `multi_color_hexes`,
  /// `multi_color_direction`, `extra`.
  factory GetFilament.fromJson(Map<String, dynamic> json) {
    final vendorJson = JsonUtil.tryParseMap(json['vendor']);
    return GetFilament(
      id: JsonUtil.tryParseInt(json['id']) ?? 0,
      registered: JsonUtil.tryParseDate(json['registered']) ?? DateTime.now(),
      name: JsonUtil.tryParseString(json['name']),
      vendor: vendorJson == null ? null : GetVendor.fromJson(vendorJson),
      material: JsonUtil.tryParseString(json['material']),
      price: JsonUtil.tryParseDouble(json['price']),
      density: JsonUtil.tryParseDouble(json['density']) ?? 0,
      diameter: JsonUtil.tryParseDouble(json['diameter']) ?? 1.75,
      weight: JsonUtil.tryParseDouble(json['weight']),
      spoolWeight: JsonUtil.tryParseDouble(json['spool_weight']),
      articleNumber: JsonUtil.tryParseString(json['article_number']),
      comment: JsonUtil.tryParseString(json['comment']),
      settingsExtruderTemp: JsonUtil.tryParseInt(json['settings_extruder_temp']),
      settingsBedTemp: JsonUtil.tryParseInt(json['settings_bed_temp']),
      colorHex: JsonUtil.tryParseString(json['color_hex']),
      externalId: JsonUtil.tryParseString(json['external_id']),
      multiColorHexes: JsonUtil.tryParseString(json['multi_color_hexes']),
      multiColorDirection: JsonUtil.tryParseString(json['multi_color_direction']),
      extra: JsonUtil.tryParseMap(json['extra']),
    );
  }

  @override
  final int id;
  final DateTime registered;
  final String? name;
  final GetVendor? vendor;
  final String? material;
  final double? price;
  final double density;
  final double diameter;
  final double? weight;
  final double? spoolWeight;
  final String? articleNumber;
  final String? comment;
  final int? settingsExtruderTemp;
  final int? settingsBedTemp;
  final String? colorHex;
  final String? externalId;
  final String? multiColorHexes;
  final String? multiColorDirection;
  final Map<String, dynamic>? extra;

  GetFilament copyWith({
    String? name,
    GetVendor? vendor,
    String? material,
    double? price,
    double? density,
    double? diameter,
    double? weight,
    double? spoolWeight,
    String? articleNumber,
    String? comment,
    int? settingsExtruderTemp,
    int? settingsBedTemp,
    String? colorHex,
    String? externalId,
    String? multiColorHexes,
    String? multiColorDirection,
    Map<String, dynamic>? extra,
  }) {
    return GetFilament(
      id: id,
      registered: registered,
      name: name ?? this.name,
      vendor: vendor ?? this.vendor,
      material: material ?? this.material,
      price: price ?? this.price,
      density: density ?? this.density,
      diameter: diameter ?? this.diameter,
      weight: weight ?? this.weight,
      spoolWeight: spoolWeight ?? this.spoolWeight,
      articleNumber: articleNumber ?? this.articleNumber,
      comment: comment ?? this.comment,
      settingsExtruderTemp: settingsExtruderTemp ?? this.settingsExtruderTemp,
      settingsBedTemp: settingsBedTemp ?? this.settingsBedTemp,
      colorHex: colorHex ?? this.colorHex,
      externalId: externalId ?? this.externalId,
      multiColorHexes: multiColorHexes ?? this.multiColorHexes,
      multiColorDirection: multiColorDirection ?? this.multiColorDirection,
      extra: extra ?? this.extra,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GetFilament &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          registered == other.registered &&
          name == other.name &&
          vendor == other.vendor &&
          material == other.material &&
          price == other.price &&
          density == other.density &&
          diameter == other.diameter &&
          weight == other.weight &&
          spoolWeight == other.spoolWeight &&
          articleNumber == other.articleNumber &&
          comment == other.comment &&
          settingsExtruderTemp == other.settingsExtruderTemp &&
          settingsBedTemp == other.settingsBedTemp &&
          colorHex == other.colorHex &&
          externalId == other.externalId &&
          multiColorHexes == other.multiColorHexes &&
          multiColorDirection == other.multiColorDirection &&
          mapEquals(extra, other.extra);

  @override
  int get hashCode => Object.hash(
        id,
        registered,
        name,
        vendor,
        material,
        price,
        density,
        diameter,
        weight,
        spoolWeight,
        articleNumber,
        comment,
        settingsExtruderTemp,
        settingsBedTemp,
        colorHex,
        externalId,
        multiColorHexes,
        multiColorDirection,
        extra == null ? null : Object.hashAllUnordered(extra!.entries.map((e) => Object.hash(e.key, e.value))),
      );

  @override
  String toString() => 'GetFilament{id: $id, name: $name, material: $material}';
}
