/*
 * Copyright (c) 2024-2026. Patrick Schmidt.
 * All rights reserved.
 */

import '../enums/rotation_enum.dart';

/// Opções resolvidas do visualizador de G-code.
class VisualizerOptions {
  const VisualizerOptions({
    this.showGrid = true,
    this.showAxes = true,
    this.showExtrusion = true,
    this.showRetraction = true,
    this.showTravel = true,
    this.showNextLayer = true,
    this.showPreviousLayer = true,
    this.extrusionWidthMultiplier = 1.0,
    this.rotation = RotationEnum.deg0,
  });

  final bool showGrid;
  final bool showAxes;
  final bool showExtrusion;
  final bool showRetraction;
  final bool showTravel;
  final bool showNextLayer;
  final bool showPreviousLayer;
  final double extrusionWidthMultiplier;
  final RotationEnum rotation;
}
