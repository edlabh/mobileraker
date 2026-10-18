/*
 * Copyright (c) 2024-2026. Patrick Schmidt.
 * All rights reserved.
 */

import 'package:flutter/foundation.dart';

/// Filtros aplicados às listagens do Spoolman.
class SpoolmanFilter {
  const SpoolmanFilter(this.filters);

  SpoolmanFilter.empty() : filters = const <String, dynamic>{};

  final Map<String, dynamic> filters;

  bool get isEmpty => filters.isEmpty;
  bool get isNotEmpty => filters.isNotEmpty;

  SpoolmanFilter copyWith(Map<String, dynamic> filters) => SpoolmanFilter(filters);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is SpoolmanFilter && mapEquals(filters, other.filters);

  @override
  int get hashCode =>
      Object.hashAllUnordered(filters.entries.map((e) => Object.hash(e.key, e.value)));

  @override
  String toString() => 'SpoolmanFilter{$filters}';
}
