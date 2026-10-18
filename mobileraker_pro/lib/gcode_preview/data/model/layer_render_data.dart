/*
 * Copyright (c) 2024-2026. Patrick Schmidt.
 * All rights reserved.
 */

import 'dart:ui' show Offset;

import 'move.dart';

/// Dados prontos para desenhar uma camada (e vizinhas) no visualizador.
class LayerRenderData {
  const LayerRenderData({
    required this.metaData,
    this.currentLayer,
    this.currentLayerDrawCount = 0,
    this.previousLayer,
    this.nextLayer,
    this.position,
  });

  final LayerMetaData metaData;

  /// Movimentos da camada atual (desenhar de 0 até [currentLayerDrawCount]).
  final List<Move>? currentLayer;
  final int currentLayerDrawCount;

  /// Camada anterior (completa) — exibida em modo "fantasma" quando habilitado.
  final List<Move>? previousLayer;

  /// Próxima camada (completa) — exibida em modo "fantasma" quando habilitado.
  final List<Move>? nextLayer;

  /// Posição do toolhead após o último movimento desenhado.
  final Offset? position;
}

/// Metadados de uma camada renderizada (posições de movimento globais).
class LayerMetaData {
  const LayerMetaData({
    required this.layer,
    required this.moveStart,
    required this.moveEnd,
    required this.currentMove,
  });

  final int layer;
  final int moveStart;
  final int moveEnd;
  final int currentMove;
}
