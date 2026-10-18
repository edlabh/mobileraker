/*
 * Copyright (c) 2024-2026. Patrick Schmidt.
 * All rights reserved.
 */

import 'dart:math' as math;

import 'package:common/data/dto/config/config_file.dart';
import 'package:common/service/setting_service.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../data/enums/rotation_enum.dart';
import '../data/model/gcode_visualizer_settings_key.dart';
import '../data/model/layer_render_data.dart';
import '../data/model/move.dart';
import '../data/model/visualizer_options.dart';

/// Visualizador das camadas do G-code (vista superior da mesa).
class GCodeLayerVisualizer extends ConsumerWidget {
  const GCodeLayerVisualizer({super.key, required this.printerConfig, required this.currentLayer});

  final ConfigFile printerConfig;
  final LayerRenderData currentLayer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final options = VisualizerOptions(
      showGrid: ref.watch(boolSettingProvider(GCodeVisualizerSettingsKey.showGrid, true)),
      showAxes: ref.watch(boolSettingProvider(GCodeVisualizerSettingsKey.showAxes, true)),
      showExtrusion: ref.watch(boolSettingProvider(GCodeVisualizerSettingsKey.showExtrusion, true)),
      showRetraction: ref.watch(boolSettingProvider(GCodeVisualizerSettingsKey.showRetraction, true)),
      showTravel: ref.watch(boolSettingProvider(GCodeVisualizerSettingsKey.showTravel, true)),
      showNextLayer: ref.watch(boolSettingProvider(GCodeVisualizerSettingsKey.showNextLayer, true)),
      showPreviousLayer: ref.watch(boolSettingProvider(GCodeVisualizerSettingsKey.showPreviousLayer, true)),
      extrusionWidthMultiplier:
          ref.watch(doubleSettingProvider(GCodeVisualizerSettingsKey.extrusionWidthMultiplier, 1.0)),
    );
    final sizeX = printerConfig.sizeX > 0 ? printerConfig.sizeX : 220.0;
    final sizeY = printerConfig.sizeY > 0 ? printerConfig.sizeY : 220.0;
    return AspectRatio(
      aspectRatio: sizeX / sizeY,
      child: CustomPaint(
        painter: GCodeLayerPainter(
          bedSize: Size(sizeX, sizeY),
          data: currentLayer,
          options: options,
          theme: Theme.of(context),
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

/// Pintor do visualizador de G-code.
class GCodeLayerPainter extends CustomPainter {
  GCodeLayerPainter({required this.bedSize, required this.data, required this.options, required this.theme});

  final Size bedSize;
  final LayerRenderData data;
  final VisualizerOptions options;
  final ThemeData theme;

  @override
  void paint(Canvas canvas, Size size) {
    final colorScheme = theme.colorScheme;
    final bedW = bedSize.width;
    final bedH = bedSize.height;
    final scale = math.min(size.width * 0.9 / bedW, size.height * 0.9 / bedH);
    final ox = (size.width - bedW * scale) / 2;
    final oy = (size.height - bedH * scale) / 2;

    Offset project(double x, double y) => Offset(ox + x * scale, oy + (bedH - y) * scale);

    canvas.save();
    if (options.rotation != RotationEnum.deg0) {
      canvas.translate(size.width / 2, size.height / 2);
      canvas.rotate(options.rotation.radians);
      canvas.translate(-size.width / 2, -size.height / 2);
    }

    // Mesa
    canvas.drawRect(
      Rect.fromLTWH(ox, oy, bedW * scale, bedH * scale),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = colorScheme.outlineVariant,
    );

    // Grade de referência (10 mm)
    if (options.showGrid) {
      final gridPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5
        ..color = colorScheme.outlineVariant.withValues(alpha: 0.5);
      for (var x = 10.0; x < bedW; x += 10) {
        canvas.drawLine(project(x, 0), project(x, bedH), gridPaint);
      }
      for (var y = 10.0; y < bedH; y += 10) {
        canvas.drawLine(project(0, y), project(bedW, y), gridPaint);
      }
    }

    // Eixos
    if (options.showAxes) {
      final axisPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = colorScheme.onSurfaceVariant;
      final axisLen = math.min(bedW, bedH) * 0.12;
      canvas.drawLine(project(0, 0), project(axisLen, 0), axisPaint);
      canvas.drawLine(project(0, 0), project(0, axisLen), axisPaint);
      _drawLabel(canvas, 'X', project(axisLen, 0) + const Offset(5, -16), colorScheme.onSurfaceVariant);
      _drawLabel(canvas, 'Y', project(0, axisLen) + const Offset(-16, -6), colorScheme.onSurfaceVariant);
    }

    // Camadas vizinhas (fantasma)
    if (options.showNextLayer && data.nextLayer != null) {
      _drawGhost(canvas, project, data.nextLayer!, colorScheme.primary.withValues(alpha: 0.10));
    }
    if (options.showPreviousLayer && data.previousLayer != null) {
      _drawGhost(canvas, project, data.previousLayer!, colorScheme.primary.withValues(alpha: 0.22));
    }

    // Camada atual
    final extrusionWidth = math.max(0.6, 0.45 * scale * options.extrusionWidthMultiplier);
    _drawCurrentLayer(canvas, project, extrusionWidth, colorScheme);

    // Posição do toolhead
    final position = data.position;
    if (position != null) {
      final point = project(position.dx, position.dy);
      canvas.drawCircle(
        point,
        5,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = colorScheme.secondary,
      );
      canvas.drawCircle(point, 2, Paint()..color = colorScheme.secondary);
    }

    canvas.restore();
  }

  void _drawGhost(Canvas canvas, Offset Function(double, double) project, List<Move> moves, Color color) {
    final path = Path();
    for (final move in moves) {
      if (!move.hasMovement) continue;
      _addSegment(path, project, move);
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..strokeCap = StrokeCap.round
        ..color = color,
    );
  }

  void _drawCurrentLayer(Canvas canvas, Offset Function(double, double) project, double extrusionWidth, ColorScheme colorScheme) {
    final moves = data.currentLayer;
    if (moves == null || data.currentLayerDrawCount <= 0) return;
    final limit = math.min(data.currentLayerDrawCount, moves.length);
    final extrusionPath = Path();
    final travelPath = Path();
    final retractions = <Offset>[];
    for (var i = 0; i < limit; i++) {
      final move = moves[i];
      if (move.isExtrusion && options.showExtrusion) {
        _addSegment(extrusionPath, project, move);
      } else if (move.isRetraction && !move.hasMovement && options.showRetraction) {
        retractions.add(project(move.startX, move.startY));
      } else if (options.showTravel) {
        _addSegment(travelPath, project, move);
      }
    }
    canvas.drawPath(
      travelPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..strokeCap = StrokeCap.round
        ..color = colorScheme.tertiary.withValues(alpha: 0.75),
    );
    canvas.drawPath(
      extrusionPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = extrusionWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = colorScheme.primary,
    );
    if (retractions.isNotEmpty) {
      final retractPaint = Paint()..color = colorScheme.error;
      for (final point in retractions) {
        canvas.drawCircle(point, 2.5, retractPaint);
      }
    }
  }

  static void _addSegment(Path path, Offset Function(double, double) project, Move move) {
    final a = project(move.startX, move.startY);
    final b = project(move.endX, move.endY);
    path.moveTo(a.dx, a.dy);
    path.lineTo(b.dx, b.dy);
  }

  void _drawLabel(Canvas canvas, String text, Offset position, Color color) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, position);
  }

  @override
  bool shouldRepaint(GCodeLayerPainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.options != options ||
        oldDelegate.theme != theme ||
        oldDelegate.bedSize != bedSize;
  }
}
