/*
 * Copyright (c) 2024-2026. Patrick Schmidt.
 * All rights reserved.
 */

import 'layer.dart';

/// Estrutura completa de um G-code analisado.
class GCodeStructure {
  const GCodeStructure({required this.layers, required this.maxLayer});

  final List<Layer> layers;
  final int maxLayer;

  bool get isEmpty => layers.isEmpty;

  int get totalMoves {
    var total = 0;
    for (final layer in layers) {
      total += layer.moves.length;
    }
    return total;
  }

  static const GCodeStructure empty = GCodeStructure(
    layers: [Layer(index: 0, z: 0, moves: [], filePosStart: 0, filePosEnd: 0)],
    maxLayer: 1,
  );
}
