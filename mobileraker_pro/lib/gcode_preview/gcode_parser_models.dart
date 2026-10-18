/*
 * Copyright (c) 2024-2026. Patrick Schmidt.
 * All rights reserved.
 */

import 'data/model/layer.dart';

/// Resultado bruto da análise do G-code.
class GCodeParseResult {
  const GCodeParseResult({required this.layers, required this.maxLayer});

  final List<Layer> layers;
  final int maxLayer;

  bool get isEmpty => layers.isEmpty;
}
