/*
 * Copyright (c) 2024-2026. Patrick Schmidt.
 * All rights reserved.
 */

/// Tipos de campos extras suportados pelo Spoolman.
///
/// Valores extraídos do APK oficial (ordem dos índices preservada).
enum SpoolmanExtraType {
  text,
  integer,
  integerRange,
  float,
  floatRange,
  datetime,
  boolean,
  choice;

  static SpoolmanExtraType? fromJson(dynamic raw) {
    return switch (raw?.toString()) {
      'text' => text,
      'integer' => integer,
      'integer_range' || 'integerRange' => integerRange,
      'float' => float,
      'float_range' || 'floatRange' => floatRange,
      'datetime' => datetime,
      'boolean' => boolean,
      'choice' => choice,
      _ => null,
    };
  }
}
