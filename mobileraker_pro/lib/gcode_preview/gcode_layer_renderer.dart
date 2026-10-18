/*
 * Copyright (c) 2024-2026. Patrick Schmidt.
 * All rights reserved.
 */

import 'dart:ui' show Offset;

import 'data/model/gcode_structure.dart';
import 'data/model/layer.dart';
import 'data/model/layer_render_data.dart';

/// Fornece os dados de desenho das camadas a partir de uma [GCodeStructure].
class GCodeLayerRenderer {
  GCodeLayerRenderer(this.structure) {
    var acc = 0;
    for (final layer in structure.layers) {
      _layerMoveStarts.add(acc);
      acc += layer.moves.length;
    }
  }

  final GCodeStructure structure;
  final List<int> _layerMoveStarts = [];

  List<Layer> get _layers => structure.layers;

  LayerRenderData createRenderDataForLayer({required int layerIndex, int? stopAtMove}) {
    final layers = _layers;
    if (layers.isEmpty) return _emptyRenderData(layerIndex);
    final idx = layerIndex.clamp(0, layers.length - 1);
    final (moveStart, moveEnd) = _moveBoundsForLayer(idx);
    final currentMove = stopAtMove == null ? moveEnd : stopAtMove.clamp(moveStart, moveEnd);
    return _createLayerRenderData(idx, currentMove: currentMove, moveStart: moveStart, moveEnd: moveEnd);
  }

  LayerRenderData createRenderDataForFilePosition(int filePosition) {
    final layers = _layers;
    if (layers.isEmpty) return _emptyRenderData(0);
    final idx = _binarySearchLayerByFilePos(filePosition);
    final (moveStart, moveEnd) = _moveBoundsForLayer(idx);
    var currentMove = moveEnd;
    final moves = layers[idx].moves;
    if (moves.isNotEmpty && filePosition < moves.last.filePos) {
      currentMove = _binarySearchMoveByFilePos(idx, filePosition);
    }
    return _createLayerRenderData(idx, currentMove: currentMove, moveStart: moveStart, moveEnd: moveEnd);
  }

  LayerRenderData _createLayerRenderData(
    int idx, {
    required int currentMove,
    required int moveStart,
    required int moveEnd,
  }) {
    final layer = _layers[idx];
    final drawCount = (currentMove - moveStart + 1).clamp(0, layer.moves.length);
    Offset? position;
    if (drawCount > 0) {
      final last = layer.moves[drawCount - 1];
      position = Offset(last.endX, last.endY);
    }
    return LayerRenderData(
      metaData: LayerMetaData(layer: idx, moveStart: moveStart, moveEnd: moveEnd, currentMove: currentMove),
      currentLayer: layer.moves,
      currentLayerDrawCount: drawCount,
      previousLayer: idx > 0 ? _layers[idx - 1].moves : null,
      nextLayer: idx + 1 < _layers.length ? _layers[idx + 1].moves : null,
      position: position,
    );
  }

  LayerRenderData _emptyRenderData(int layerIndex) {
    return LayerRenderData(
      metaData: LayerMetaData(layer: layerIndex, moveStart: 0, moveEnd: 0, currentMove: 0),
    );
  }

  (int, int) _moveBoundsForLayer(int idx) {
    final start = _layerMoveStarts[idx];
    final count = _layers[idx].moves.length;
    return (start, start + (count > 0 ? count - 1 : 0));
  }

  (int, int) _filePosBoundsForLayer(int idx) {
    final layer = _layers[idx];
    return (layer.filePosStart, layer.filePosEnd);
  }

  int _binarySearchLayerByFilePos(int filePosition) {
    var lo = 0;
    var hi = _layers.length - 1;
    while (lo < hi) {
      final mid = (lo + hi + 1) >> 1;
      if (_filePosBoundsForLayer(mid).$1 <= filePosition) {
        lo = mid;
      } else {
        hi = mid - 1;
      }
    }
    return lo;
  }

  int _binarySearchMoveByFilePos(int layerIdx, int filePosition) {
    final moves = _layers[layerIdx].moves;
    var lo = 0;
    var hi = moves.length - 1;
    while (lo < hi) {
      final mid = (lo + hi + 1) >> 1;
      if (moves[mid].filePos <= filePosition) {
        lo = mid;
      } else {
        hi = mid - 1;
      }
    }
    return _layerMoveStarts[layerIdx] + lo;
  }
}
