/*
 * Copyright (c) 2024-2026. Patrick Schmidt.
 * All rights reserved.
 */

/// Atualização parcial de um fornecedor (campos `null` = inalterados).
class UpdateVendor {
  const UpdateVendor({
    required this.id,
    this.name,
    this.spoolWeight,
    this.comment,
    this.externalId,
    this.extra,
  });

  final int id;
  final String? name;
  final double? spoolWeight;
  final String? comment;
  final String? externalId;
  final Map<String, dynamic>? extra;

  /// Payload de atualização (PATCH) — chaves extraídas do APK oficial.
  Map<String, dynamic> toJson() {
    return {
      if (comment != null) 'comment': comment,
      if (spoolWeight != null) 'empty_spool_weight': spoolWeight,
      if (externalId != null) 'external_id': externalId,
      if (extra != null) 'extra': extra,
      if (name != null) 'name': name,
    };
  }

  @override
  String toString() => 'UpdateVendor{id: $id}';
}
