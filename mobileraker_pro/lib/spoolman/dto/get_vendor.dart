/*
 * Copyright (c) 2024-2026. Patrick Schmidt.
 * All rights reserved.
 */

import 'package:flutter/foundation.dart';

import '../../misc/json_util.dart';
import 'spoolman_dto_mixin.dart';

/// Fornecedor de filamento retornado pelo Spoolman.
class GetVendor implements SpoolmanIdentifiableDtoMixin {
  const GetVendor({
    required this.id,
    required this.registered,
    required this.name,
    this.comment,
    this.spoolWeight,
    this.externalId,
    this.extra,
  });

  /// Reconstrói o fornecedor a partir do payload do Spoolman.
  ///
  /// Chaves (snake_case) extraídas do APK oficial: `id`, `registered`, `name`,
  /// `comment`, `empty_spool_weight`, `external_id`, `extra`.
  factory GetVendor.fromJson(Map<String, dynamic> json) {
    return GetVendor(
      id: JsonUtil.tryParseInt(json['id']) ?? 0,
      registered: JsonUtil.tryParseDate(json['registered']) ?? DateTime.now(),
      name: JsonUtil.tryParseString(json['name']) ?? '',
      comment: JsonUtil.tryParseString(json['comment']),
      spoolWeight: JsonUtil.tryParseDouble(json['empty_spool_weight']),
      externalId: JsonUtil.tryParseString(json['external_id']),
      extra: JsonUtil.tryParseMap(json['extra']),
    );
  }

  @override
  final int id;
  final DateTime registered;
  final String name;
  final String? comment;
  final double? spoolWeight;
  final String? externalId;
  final Map<String, dynamic>? extra;

  GetVendor copyWith({
    String? name,
    String? comment,
    double? spoolWeight,
    String? externalId,
    Map<String, dynamic>? extra,
  }) {
    return GetVendor(
      id: id,
      registered: registered,
      name: name ?? this.name,
      comment: comment ?? this.comment,
      spoolWeight: spoolWeight ?? this.spoolWeight,
      externalId: externalId ?? this.externalId,
      extra: extra ?? this.extra,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GetVendor &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          registered == other.registered &&
          name == other.name &&
          comment == other.comment &&
          spoolWeight == other.spoolWeight &&
          externalId == other.externalId &&
          mapEquals(extra, other.extra);

  @override
  int get hashCode => Object.hash(
        id,
        registered,
        name,
        comment,
        spoolWeight,
        externalId,
        extra == null ? null : Object.hashAllUnordered(extra!.entries.map((e) => Object.hash(e.key, e.value))),
      );

  @override
  String toString() => 'GetVendor{id: $id, name: $name}';
}
