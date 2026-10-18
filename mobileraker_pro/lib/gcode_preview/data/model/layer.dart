/*
 * Copyright (c) 2024-2026. Patrick Schmidt.
 * All rights reserved.
 */

import 'move.dart';

/// Uma camada do G-code.
class Layer {
  const Layer({
    required this.index,
    required this.z,
    required this.moves,
    required this.filePosStart,
    required this.filePosEnd,
  });

  final int index;
  final double z;
  final List<Move> moves;
  final int filePosStart;
  final int filePosEnd;

  int get moveCount => moves.length;
}
