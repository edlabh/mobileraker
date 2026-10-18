/*
 * Copyright (c) 2024-2026. Patrick Schmidt.
 * All rights reserved.
 *
 * Validação local do analisador de G-code contra um arquivo real.
 * Uso: flutter test test/gcode_parser_check_test.dart
 */

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobileraker_pro/gcode_preview/gcode_parser.dart';
import 'package:mobileraker_pro/gcode_preview/gcode_structure_codec.dart';

void main() {
  test('parseia um gcode real e valida o codec', () {
    const path = '/tmp/opencode/gcode_samples/sample.gcode';
    final file = File(path);
    if (!file.existsSync()) {
      markTestSkipped('sample.gcode ausente em $path');
      return;
    }
    final bytes = file.readAsBytesSync();
    var progressCalls = 0;
    final result = GCodeParser.parse(bytes, onProgress: (_) => progressCalls++);
    print('arquivo: ${bytes.length} bytes');
    print('camadas: ${result.layers.length} (maxLayer=${result.maxLayer})');
    final totalMoves = result.layers.fold<int>(0, (sum, l) => sum + l.moves.length);
    print('movimentos: $totalMoves');
    print('progresso reportado: $progressCalls vezes');

    expect(result.layers, isNotEmpty);
    expect(result.maxLayer, result.layers.length);
    expect(result.layers.first.moves, isNotEmpty);

    for (final layer in result.layers) {
      expect(layer.filePosStart, lessThanOrEqualTo(layer.filePosEnd));
      for (final move in layer.moves) {
        expect(move.filePos, greaterThanOrEqualTo(0));
      }
    }

    final encoded = GCodeStructureCodec.encode(result.layers, result.maxLayer);
    final decoded = GCodeStructureCodec.decode(encoded);
    expect(decoded.layers.length, result.layers.length);
    expect(decoded.maxLayer, result.maxLayer);
    expect(decoded.layers[0].moves.length, result.layers[0].moves.length);
    final original = result.layers.last.moves.last;
    final roundTrip = decoded.layers.last.moves.last;
    expect(roundTrip.endX, closeTo(original.endX, 0.001));
    expect(roundTrip.endY, closeTo(original.endY, 0.001));
    expect(roundTrip.filePos, original.filePos);
    print('codec: ${encoded.length} bytes (${(encoded.length / bytes.length * 100).toStringAsFixed(1)}% do gcode)');

    for (var i = 0; i < result.layers.length && i < 3; i++) {
      final layer = result.layers[i];
      final extrusions = layer.moves.where((m) => m.isExtrusion).length;
      final travels = layer.moves.where((m) => m.isTravel).length;
      final retracts = layer.moves.where((m) => m.isRetraction).length;
      print('  camada $i: z=${layer.z.toStringAsFixed(2)} movimentos=${layer.moves.length} '
          '(extrusão=$extrusions travel=$travels retração=$retracts) '
          'filePos=[${layer.filePosStart}, ${layer.filePosEnd}]');
    }
  });
}
