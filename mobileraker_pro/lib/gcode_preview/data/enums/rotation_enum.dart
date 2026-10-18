/*
 * Copyright (c) 2024-2026. Patrick Schmidt.
 * All rights reserved.
 */

import 'dart:math' as math;

/// Rotação aplicada à visualização do G-code (passos de 90°).
enum RotationEnum {
  deg0(0),
  deg90(90),
  deg180(180),
  deg270(270);

  const RotationEnum(this.degrees);

  final int degrees;

  double get radians => degrees * math.pi / 180;
}
