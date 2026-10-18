/*
 * Copyright (c) 2024-2026. Patrick Schmidt.
 * All rights reserved.
 */

import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import 'gcode_parser.dart';
import 'gcode_structure_codec.dart';

/// Erro ocorrido durante a análise do G-code.
class GCodeParseException implements Exception {
  const GCodeParseException(this.message);

  final String message;

  @override
  String toString() => 'GCodeParseException: $message';
}

/// Executa a análise do G-code em um isolate separado, reportando progresso.
class GCodeParserWorker {
  const GCodeParserWorker._();

  static Future<Uint8List> parse(Uint8List bytes, {void Function(double progress)? onProgress}) async {
    final receivePort = ReceivePort();
    final completer = Completer<Uint8List>();
    var done = false;
    receivePort.listen((message) {
      if (done) return;
      if (message is Map) {
        switch (message['type']) {
          case 'progress':
            onProgress?.call((message['progress'] as num).toDouble());
          case 'done':
            done = true;
            completer.complete((message['data'] as TransferableTypedData).materialize().asUint8List());
          case 'error':
            done = true;
            completer.completeError(GCodeParseException(message['error'] as String? ?? 'erro desconhecido'));
        }
      } else if (message is List && message.length == 2) {
        done = true;
        completer.completeError(GCodeParseException('${message[0]}'));
      } else {
        done = true;
        completer.completeError(const GCodeParseException('Analisador GCode encerrou inesperadamente'));
      }
    });
    await Isolate.spawn(
      _workerEntry,
      [TransferableTypedData.fromList([bytes]), receivePort.sendPort],
      debugName: 'GCodeParserWorker',
      onExit: receivePort.sendPort,
      onError: receivePort.sendPort,
      errorsAreFatal: true,
    );
    try {
      return await completer.future.timeout(const Duration(minutes: 5));
    } on TimeoutException {
      throw const GCodeParseException('Tempo esgotado durante a análise do G-code');
    } finally {
      receivePort.close();
    }
  }
}

void _workerEntry(List<Object?> args) {
  final data = args[0] as TransferableTypedData;
  final port = args[1] as SendPort;
  try {
    final bytes = data.materialize().asUint8List();
    final result = GCodeParser.parse(
      bytes,
      onProgress: (progress) => port.send({'type': 'progress', 'progress': progress}),
    );
    final codecBytes = GCodeStructureCodec.encode(result.layers, result.maxLayer);
    port.send({'type': 'done', 'data': TransferableTypedData.fromList([codecBytes])});
  } catch (error) {
    port.send({'type': 'error', 'error': '$error'});
  }
}
