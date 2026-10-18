/*
 * Copyright (c) 2024-2026. Patrick Schmidt.
 * All rights reserved.
 */

/// Helpers para interpretar os payloads JSON (snake_case) do Spoolman.
class JsonUtil {
  const JsonUtil._();

  static DateTime? tryParseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    final raw = value.toString();
    if (raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  static double? tryParseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static int? tryParseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static bool? tryParseBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    return null;
  }

  static String? tryParseString(dynamic value) {
    if (value == null) return null;
    final raw = value.toString();
    return raw.isEmpty ? null : raw;
  }

  static Map<String, dynamic>? tryParseMap(dynamic value) {
    if (value is! Map) return null;
    return value.map((key, v) => MapEntry(key.toString(), v));
  }

  static List<String>? tryParseStringList(dynamic value) {
    if (value is! List) return null;
    return [for (final entry in value) entry.toString()];
  }
}
