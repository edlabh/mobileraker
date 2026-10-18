/*
 * Copyright (c) 2024-2026. Patrick Schmidt.
 * All rights reserved.
 */

import 'dart:math' as math;

/// Um movimento do G-code (segmento de extrusão, deslocamento ou retração).
class Move {
  const Move({
    required this.startX,
    required this.startY,
    required this.endX,
    required this.endY,
    required this.extrusion,
    required this.filePos,
  });

  final double startX;
  final double startY;
  final double endX;
  final double endY;

  /// Variação de extrusão em mm (positivo extrusa, negativo retrai).
  final double extrusion;

  /// Posição em bytes do início da linha no arquivo (preview ao vivo).
  final int filePos;

  static const double _eps = 1e-4;

  bool get isExtrusion => extrusion > _eps;
  bool get isRetraction => extrusion < -_eps;
  bool get isTravel => !isExtrusion && !isRetraction;
  bool get hasMovement => (endX - startX).abs() > _eps || (endY - startY).abs() > _eps;

  double get length {
    final dx = endX - startX;
    final dy = endY - startY;
    return math.sqrt(dx * dx + dy * dy);
  }
}
