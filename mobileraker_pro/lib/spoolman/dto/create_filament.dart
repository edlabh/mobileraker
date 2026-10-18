/*
 * Copyright (c) 2024-2026. Patrick Schmidt.
 * All rights reserved.
 */

import 'get_vendor.dart';

/// Dados para criar um filamento no Spoolman.
class CreateFilament {
  const CreateFilament({
    this.name,
    this.vendor,
    this.material,
    this.price,
    this.density,
    this.diameter,
    this.weight,
    this.spoolWeight,
    this.articleNumber,
    this.settingsExtruderTemp,
    this.settingsBedTemp,
    this.colorHex,
    this.externalId,
    this.multiColorHexes,
    this.multiColorDirection,
    this.comment,
    this.extra,
  });

  final String? name;
  final GetVendor? vendor;
  final String? material;
  final double? price;
  final double? density;
  final double? diameter;
  final double? weight;
  final double? spoolWeight;
  final String? articleNumber;
  final int? settingsExtruderTemp;
  final int? settingsBedTemp;
  final String? colorHex;
  final String? externalId;
  final String? multiColorHexes;
  final String? multiColorDirection;
  final String? comment;
  final Map<String, dynamic>? extra;

  /// Payload de criação — chaves extraídas do APK oficial.
  Map<String, dynamic> toJson() {
    return {
      if (articleNumber != null) 'article_number': articleNumber,
      if (colorHex != null) 'color_hex': colorHex,
      if (comment != null) 'comment': comment,
      if (density != null) 'density': density,
      if (diameter != null) 'diameter': diameter,
      if (externalId != null) 'external_id': externalId,
      if (extra != null) 'extra': extra,
      if (material != null) 'material': material,
      if (multiColorDirection != null) 'multi_color_direction': multiColorDirection,
      if (multiColorHexes != null) 'multi_color_hexes': multiColorHexes,
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
  String toString() => 'CreateFilament{name: $name, material: $material, vendor: $vendor}';
}
