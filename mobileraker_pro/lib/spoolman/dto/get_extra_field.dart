/*
 * Copyright (c) 2024-2026. Patrick Schmidt.
 * All rights reserved.
 */

import '../../misc/json_util.dart';
import 'spoolman_entity_type_enum.dart';
import 'spoolman_extra_type_enum.dart';

/// Prefixo usado nos nomes dos campos do formulário (`FormBuilder`) dos
/// campos extras do Spoolman — permite reconstruir o mapa `extra` da
/// entidade a partir dos dados do formulário ([ExtraFieldsFormExtension]).
const String spoolmanExtraFieldPrefix = 'extra_';

/// Definição de um campo extra configurado no servidor Spoolman.
///
/// Chaves (snake_case) extraídas do APK oficial: `key`, `name`, `entity_type`,
/// `field_type`, `multi_choice`, `default_value`, `choices`, `unit`, `order`.
class GetExtraField {
  const GetExtraField({
    required this.key,
    this.name,
    this.entityType,
    this.fieldType,
    this.multiChoice,
    this.defaultValue,
    this.choices,
    this.unit,
    this.order,
  });

  factory GetExtraField.fromJson(Map<String, dynamic> json) {
    return GetExtraField(
      key: JsonUtil.tryParseString(json['key']) ?? '',
      name: JsonUtil.tryParseString(json['name']),
      entityType: _entityTypeFrom(json['entity_type']),
      fieldType: SpoolmanExtraType.fromJson(json['field_type']),
      multiChoice: JsonUtil.tryParseBool(json['multi_choice']),
      defaultValue: JsonUtil.tryParseString(json['default_value']),
      choices: JsonUtil.tryParseStringList(json['choices']),
      unit: JsonUtil.tryParseString(json['unit']),
      order: JsonUtil.tryParseInt(json['order']),
    );
  }

  final String key;
  final String? name;
  final SpoolmanEntityType? entityType;
  final SpoolmanExtraType? fieldType;
  final bool? multiChoice;
  final String? defaultValue;
  final List<String>? choices;
  final String? unit;
  final int? order;

  /// Nome deste campo no formulário (`FormBuilder`) do app.
  String get formFieldName => '$spoolmanExtraFieldPrefix$key';

  static SpoolmanEntityType? _entityTypeFrom(dynamic raw) {
    return switch (raw?.toString()) {
      'spool' => SpoolmanEntityType.spool,
      'filament' => SpoolmanEntityType.filament,
      'vendor' => SpoolmanEntityType.vendor,
      _ => null,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GetExtraField && runtimeType == other.runtimeType && key == other.key;

  @override
  int get hashCode => key.hashCode;

  @override
  String toString() => 'GetExtraField{key: $key, name: $name, fieldType: $fieldType}';
}
