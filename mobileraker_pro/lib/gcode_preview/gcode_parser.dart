/*
 * Copyright (c) 2024-2026. Patrick Schmidt.
 * All rights reserved.
 */

import 'dart:math' as math;
import 'dart:typed_data';

import 'data/model/layer.dart';
import 'data/model/move.dart';
import 'gcode_parser_models.dart';

/// Analisador de G-code.
///
/// Percorre o arquivo byte a byte, guardando a posição em bytes de cada linha
/// (necessária para o preview ao vivo via `file_position` do Moonraker) e
/// agrupando os movimentos por camada.
///
/// Detecção de camadas: se o arquivo possuir marcadores de camada
/// (`;LAYER...`), eles comandam a quebra; caso contrário, uma nova camada é
/// iniciada quando uma extrusão acontece em um Z maior.
const int _lf = 10;
const int _space = 32;
const double _extrusionEps = 1e-4;
const double _movementEps = 1e-4;
const double _layerZenith = 0.005;

class GCodeParser {
  const GCodeParser._();

  static GCodeParseResult parse(Uint8List bytes, {void Function(double progress)? onProgress}) {
    final state = _ParserState(bytes);
    final total = bytes.length;
    final step = total <= 100 ? 1 : total ~/ 100;

    var lineStart = 0;
    var nextReport = step;
    while (lineStart < total) {
      var lineEnd = lineStart;
      while (lineEnd < total && bytes[lineEnd] != _lf) {
        lineEnd++;
      }
      state.parseLine(lineStart, lineEnd);
      lineStart = lineEnd + 1;
      if (lineStart >= nextReport) {
        onProgress?.call((lineStart / total).clamp(0.0, 1.0));
        nextReport += step;
      }
    }
    onProgress?.call(1);
    return state.build();
  }
}

class _ParserState {
  _ParserState(this.bytes);

  final Uint8List bytes;

  // Posição e modos da máquina
  double posX = 0;
  double posY = 0;
  double posZ = 0;
  double ePos = 0;
  bool absXYZ = true;
  bool absE = true;
  bool sawLayerMarker = false;
  bool pendingLayerBreak = false;

  // Camadas
  bool layerOpen = false;
  double currentZ = 0;
  final List<Move> leadingMoves = [];
  final List<Move> currentMoves = [];
  final List<List<Move>> layersMoves = [];
  final List<double> layersZ = [];

  void parseLine(int start, int end) {
    var p = start;
    while (p < end && bytes[p] == _space) {
      p++;
    }
    if (p >= end) return;

    final first = bytes[p];
    if (first == 59 /* ; */) {
      if (_commentIsLayerChange(p + 1, end)) {
        sawLayerMarker = true;
        pendingLayerBreak = true;
      }
      return;
    }
    if (first == 40 /* ( */) return;

    p++;
    final (code, afterCode) = _readNumber(p, end);
    final codeInt = code.round();
    switch (first) {
      case 71 /* G */ :
      case 103 /* g */ :
        switch (codeInt) {
          case 0:
          case 1:
            _handleMove(afterCode, end, start);
          case 2:
            _handleArc(afterCode, end, start, clockwise: true);
          case 3:
            _handleArc(afterCode, end, start, clockwise: false);
          case 28:
            _handleHome(afterCode, end);
          case 90:
            absXYZ = true;
          case 91:
            absXYZ = false;
          case 92:
            _handleSetPosition(afterCode, end);
        }
      case 77 /* M */ :
      case 109 /* m */ :
        switch (codeInt) {
          case 82:
            absE = true;
          case 83:
            absE = false;
        }
    }
  }

  void _handleMove(int start, int end, int filePos) {
    var p = start;
    double? x, y, z, e;
    while (p < end) {
      while (p < end && bytes[p] == _space) {
        p++;
      }
      if (p >= end) break;
      final letter = bytes[p];
      if (letter == 59 /* ; */) break;
      p++;
      final (value, next) = _readNumber(p, end);
      p = next > p ? next : p + 1;
      switch (letter) {
        case 88 /* X */ :
          x = value;
        case 89 /* Y */ :
          y = value;
        case 90 /* Z */ :
          z = value;
        case 69 /* E */ :
          e = value;
      }
    }
    final newX = x == null ? posX : (absXYZ ? x : posX + x);
    final newY = y == null ? posY : (absXYZ ? y : posY + y);
    final newZ = z == null ? posZ : (absXYZ ? z : posZ + z);
    final dE = _consumeExtrusion(e);
    _pushMove(posX, posY, newX, newY, dE, newZ, filePos);
    posX = newX;
    posY = newY;
    posZ = newZ;
  }

  void _handleArc(int start, int end, int filePos, {required bool clockwise}) {
    var p = start;
    double? x, y, z, e, i, j, r;
    while (p < end) {
      while (p < end && bytes[p] == _space) {
        p++;
      }
      if (p >= end) break;
      final letter = bytes[p];
      if (letter == 59 /* ; */) break;
      p++;
      final (value, next) = _readNumber(p, end);
      p = next > p ? next : p + 1;
      switch (letter) {
        case 88:
          x = value;
        case 89:
          y = value;
        case 90:
          z = value;
        case 69:
          e = value;
        case 73 /* I */ :
          i = value;
        case 74 /* J */ :
          j = value;
        case 82 /* R */ :
          r = value;
      }
    }
    final sx = posX, sy = posY;
    final newX = x == null ? posX : (absXYZ ? x : posX + x);
    final newY = y == null ? posY : (absXYZ ? y : posY + y);
    final newZ = z == null ? posZ : (absXYZ ? z : posZ + z);
    final dE = _consumeExtrusion(e);

    // Centro do arco
    double? cx;
    double? cy;
    if (i != null || j != null) {
      cx = sx + (i ?? 0);
      cy = sy + (j ?? 0);
    } else if (r != null && r != 0) {
      final center = _centerFromRadius(sx, sy, newX, newY, r, clockwise);
      if (center != null) {
        cx = center.$1;
        cy = center.$2;
      }
    }

    final dxs = cx == null ? 0.0 : sx - cx;
    final dys = cy == null ? 0.0 : sy - cy;
    final radius = math.sqrt(dxs * dxs + dys * dys);
    if (cx == null || cy == null || radius < 1e-9) {
      _pushMove(sx, sy, newX, newY, dE, newZ, filePos);
      posX = newX;
      posY = newY;
      posZ = newZ;
      return;
    }

    final a0 = math.atan2(dys, dxs);
    var sweep = math.atan2(newY - cy, newX - cx) - a0;
    if (clockwise) {
      while (sweep >= 0) {
        sweep -= 2 * math.pi;
      }
    } else {
      while (sweep <= 0) {
        sweep += 2 * math.pi;
      }
    }
    if (r != null && r < 0) {
      // arco maior
      sweep += clockwise ? -2 * math.pi : 2 * math.pi;
    }

    final segments = math.max(2, (sweep.abs() / (math.pi / 18)).ceil());
    final stepE = dE / segments;
    var prevX = sx;
    var prevY = sy;
    for (var k = 1; k <= segments; k++) {
      final a = a0 + sweep * k / segments;
      final nx = cx + radius * math.cos(a);
      final ny = cy + radius * math.sin(a);
      _pushMove(prevX, prevY, nx, ny, stepE, newZ, filePos);
      prevX = nx;
      prevY = ny;
    }
    posX = newX;
    posY = newY;
    posZ = newZ;
  }

  void _handleHome(int start, int end) {
    var p = start;
    var sawAxis = false;
    while (p < end) {
      while (p < end && bytes[p] == _space) {
        p++;
      }
      if (p >= end) break;
      final letter = bytes[p] | 0x20; // minúsculo
      if (letter == 59) break;
      if (letter == 120 /* x */) {
        posX = 0;
        sawAxis = true;
      } else if (letter == 121 /* y */) {
        posY = 0;
        sawAxis = true;
      } else if (letter == 122 /* z */) {
        posZ = 0;
        sawAxis = true;
      }
      p++;
      final (_, next) = _readNumber(p, end);
      if (next > p) p = next;
    }
    if (!sawAxis) {
      posX = 0;
      posY = 0;
      posZ = 0;
    }
  }

  void _handleSetPosition(int start, int end) {
    var p = start;
    while (p < end) {
      while (p < end && bytes[p] == _space) {
        p++;
      }
      if (p >= end) break;
      final letter = bytes[p];
      if (letter == 59) break;
      p++;
      final (value, next) = _readNumber(p, end);
      p = next > p ? next : p + 1;
      switch (letter) {
        case 88 /* X */ :
          posX = value;
        case 89 /* Y */ :
          posY = value;
        case 90 /* Z */ :
          posZ = value;
        case 69 /* E */ :
          ePos = value;
      }
    }
  }

  double _consumeExtrusion(double? e) {
    if (e == null) return 0;
    if (absE) {
      final delta = e - ePos;
      ePos = e;
      return delta;
    }
    ePos += e;
    return e;
  }

  void _pushMove(double sx, double sy, double ex, double ey, double dE, double z, int filePos) {
    final xyMove = (ex - sx).abs() > _movementEps || (ey - sy).abs() > _movementEps;
    if (dE > _extrusionEps) {
      _maybeStartLayer(z);
    }
    if (xyMove || dE.abs() > _extrusionEps) {
      final move = Move(startX: sx, startY: sy, endX: ex, endY: ey, extrusion: dE, filePos: filePos);
      if (layerOpen) {
        currentMoves.add(move);
      } else {
        leadingMoves.add(move);
      }
    }
  }

  void _maybeStartLayer(double z) {
    if (!layerOpen) {
      layerOpen = true;
      currentZ = z;
      currentMoves.addAll(leadingMoves);
      leadingMoves.clear();
      pendingLayerBreak = false;
      return;
    }
    final newLayer = sawLayerMarker ? pendingLayerBreak : z > currentZ + _layerZenith;
    if (newLayer) {
      layersMoves.add(List.of(currentMoves));
      layersZ.add(currentZ);
      currentMoves.clear();
      currentZ = z;
    }
    pendingLayerBreak = false;
  }

  GCodeParseResult build() {
    if (layerOpen) {
      layersMoves.add(List.of(currentMoves));
      layersZ.add(currentZ);
      layerOpen = false;
    }
    final layers = <Layer>[];
    for (var i = 0; i < layersMoves.length; i++) {
      final moves = List<Move>.unmodifiable(layersMoves[i]);
      if (moves.isEmpty) continue;
      layers.add(Layer(
        index: layers.length,
        z: layersZ[i],
        moves: moves,
        filePosStart: moves.first.filePos,
        filePosEnd: moves.last.filePos,
      ));
    }
    return GCodeParseResult(layers: layers, maxLayer: layers.length);
  }

  bool _commentIsLayerChange(int p, int end) {
    var i = p;
    while (i < end && bytes[i] == _space) {
      i++;
    }
    if (i + 5 > end) return false;
    return (bytes[i] | 0x20) == 108 /* l */
        && (bytes[i + 1] | 0x20) == 97 /* a */
        && (bytes[i + 2] | 0x20) == 121 /* y */
        && (bytes[i + 3] | 0x20) == 101 /* e */
        && (bytes[i + 4] | 0x20) == 114 /* r */;
  }

  (double, double)? _centerFromRadius(double sx, double sy, double tx, double ty, double r, bool clockwise) {
    final dx = tx - sx;
    final dy = ty - sy;
    final d = math.sqrt(dx * dx + dy * dy);
    if (d < 1e-9 || d > 2 * r.abs() + 1e-9) return null;
    final midX = (sx + tx) / 2;
    final midY = (sy + ty) / 2;
    final hSq = r * r - (d * d) / 4;
    final h = hSq <= 0 ? 0.0 : math.sqrt(hSq);
    final ux = -dy / d;
    final uy = dx / d;
    final c1x = midX + ux * h;
    final c1y = midY + uy * h;
    final c2x = midX - ux * h;
    final c2y = midY - uy * h;
    final s1 = _sweepFor(c1x, c1y, sx, sy, tx, ty, clockwise);
    final wantMajor = r < 0;
    final c1IsMajor = s1.abs() > math.pi;
    return wantMajor == c1IsMajor ? (c1x, c1y) : (c2x, c2y);
  }

  double _sweepFor(double cx, double cy, double sx, double sy, double tx, double ty, bool clockwise) {
    final a0 = math.atan2(sy - cy, sx - cx);
    var sweep = math.atan2(ty - cy, tx - cx) - a0;
    if (clockwise) {
      while (sweep >= 0) {
        sweep -= 2 * math.pi;
      }
    } else {
      while (sweep <= 0) {
        sweep += 2 * math.pi;
      }
    }
    return sweep;
  }

  (double, int) _readNumber(int p, int end) {
    final d = bytes;
    var i = p;
    var sign = 1.0;
    if (i < end && d[i] == 45 /* - */) {
      sign = -1;
      i++;
    } else if (i < end && d[i] == 43 /* + */) {
      i++;
    }
    var value = 0.0;
    var hasDigits = false;
    while (i < end) {
      final c = d[i];
      if (c < 48 || c > 57) break;
      value = value * 10 + (c - 48);
      hasDigits = true;
      i++;
    }
    if (i < end && d[i] == 46 /* . */) {
      i++;
      var scale = 0.1;
      while (i < end) {
        final c = d[i];
        if (c < 48 || c > 57) break;
        value += (c - 48) * scale;
        scale *= 0.1;
        hasDigits = true;
        i++;
      }
    }
    if (!hasDigits) return (0.0, p);
    return (sign * value, i);
  }
}
