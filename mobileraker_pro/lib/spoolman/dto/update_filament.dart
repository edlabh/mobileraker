/*
 * Copyright (c) 2024-2026. Patrick Schmidt.
 * All rights reserved.
 */

import 'get_vendor.dart';

/// Atualização parcial de um filamento (campos `null` = inalterados).
class UpdateFilament {
  const UpdateFilament({
    required this.id,
    this.name,
    this.vendor,
    this.material,
    this.price,
    this.density,
    this.diameter,
    this.weight,
    this.spoolWeight,
    this.articleNumber,
    this.comment,
    this.settingsExtruderTemp,
    this.settingsBedTemp,
    this.colorHex,
    this.extra,
  });

  final int id;
  final String? name;
  final GetVendor? vendor;
  final String? material;
  final double? price;
  final double? density;
  final double? diameter;
  final double? weight;
  final double? spoolWeight;
  final String? articleNumber;
  final String? comment;
  final int? settingsExtruderTemp;
  final int? settingsBedTemp;
  final String? colorHex;
  final Map<String, dynamic>? extra;

  /// Payload de atualização (PATCH) — chaves extraídas do APK oficial.
  Map<String, dynamic> toJson() {
    return {
      if (articleNumber != null) 'article_number': articleNumber,
      if (colorHex != null) 'color_hex': colorHex,
      if (comment != null) 'comment': comment,
      if (density != null) 'density': density,
      if (diameter != null) 'diameter': diameter,
      if (extra != null) 'extra': extra,
      if (material != null) 'material': material,
      if (name != null) 'name': name,
      if (price != null) 'price': price,
      if (settingsBedTemp != null) 'settings_bed_temp': settingsBedTemp,
      if (settingsExtruderTemp != null) 'settings_extruder_temp': settingsExtruderTemp,
      if (spoolWeight != null) 'spool_weight': spoolWeight,
      if (vendor != null) 'vendor_id': vendor!.id,
      if (weight != null) 'weight': weight,
    };
  }

  @override
  String toString() => 'UpdateFilament{id: $id}';
}
