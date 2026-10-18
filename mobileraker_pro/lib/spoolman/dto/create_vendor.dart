/*
 * Copyright (c) 2024-2026. Patrick Schmidt.
 * All rights reserved.
 */

/// Dados para criar um fornecedor no Spoolman.
class CreateVendor {
  const CreateVendor({
    this.name,
    this.spoolWeight,
    this.externalId,
    this.comment,
    this.extra,
  });

  final String? name;
  final double? spoolWeight;
  final String? externalId;
  final String? comment;
  final Map<String, dynamic>? extra;

  /// Payload de criação — chaves extraídas do APK oficial
  /// (`empty_spool_weight` é o nome usado pelo Spoolman).
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
  String toString() => 'CreateVendor{name: $name}';
}
