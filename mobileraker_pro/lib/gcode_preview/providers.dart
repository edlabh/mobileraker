/*
 * Copyright (c) 2024-2026. Patrick Schmidt.
 * All rights reserved.
 */

import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:common/data/dto/files/gcode_file.dart';
import 'package:common/data/model/file_operation.dart';
import 'package:common/service/moonraker/file_service.dart';
import 'package:common/util/logger.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'data/model/gcode_structure.dart';
import 'gcode_parser_worker.dart';
import 'gcode_structure_codec.dart';

/// Erro de preparação do preview de G-code.
class GCodePreviewException implements Exception {
  const GCodePreviewException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Carrega a estrutura do G-code: cache local → download → análise em isolate.
final class GCodeStructureNotifier extends AsyncNotifier<GCodeStructure> {
  GCodeStructureNotifier(this.args);

  final (String, GCodeFile) args;

  String get _machineUUID => args.$1;
  GCodeFile get _file => args.$2;

  @override
  Future<GCodeStructure> build() async {
    // 1) Cache local (estrutura já analisada)
    final cacheFile = await _cacheFile(_machineUUID, _file);
    try {
      if (await cacheFile.exists()) {
        final bytes = await cacheFile.readAsBytes();
        if (bytes.length > 16) {
          final structure = await _decodeInIsolate(bytes);
          talker.debug('GCodeStructure: cache hit para ${_file.relativeToRoot}');
          return structure;
        }
      }
    } catch (error) {
      talker.warning('GCodeStructure: cache inválido para ${_file.relativeToRoot}: $error');
    }

    // 2) Download (0.0 – 0.5)
    final fileService = ref.watch(fileServiceProvider(_machineUUID));
    File? downloaded;
    await for (final operation in fileService.downloadFile(
      filePath: _file.absolutPath,
      expectedFileSize: _file.size > 0 ? _file.size : null,
    )) {
      switch (operation) {
        case FileOperationProgress(:final progress):
          state = AsyncLoading<GCodeStructure>(progress: (progress * 0.5).clamp(0.0, 0.5));
        case FileDownloadComplete(file: final localFile):
          downloaded = localFile;
        case FileOperationCanceled():
          throw const GCodePreviewException('Download do GCode cancelado');
        default:
          break;
      }
    }
    if (downloaded == null) {
      throw const GCodePreviewException('Falha ao baixar o arquivo GCode');
    }

    // 3) Análise em isolate (0.5 – 1.0)
    final bytes = await downloaded.readAsBytes();
    final codecBytes = await GCodeParserWorker.parse(
      bytes,
      onProgress: (progress) => state = AsyncLoading<GCodeStructure>(progress: (0.5 + progress * 0.5).clamp(0.5, 1.0)),
    );

    // 4) Cache + decodificação
    await _writeToCache(cacheFile, codecBytes);
    return _decodeInIsolate(codecBytes);
  }

  static Future<File> _cacheFile(String machineUUID, GCodeFile file) async {
    final dir = Directory('${Directory.systemTemp.path}/mobileraker_gcode_preview');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    final key = '${machineUUID}_${file.relativeToRoot}_${file.size}_${file.modified}';
    return File('${dir.path}/${_fnv1a(key)}.gpv');
  }

  static Future<void> _writeToCache(File cacheFile, Uint8List bytes) async {
    try {
      await cacheFile.writeAsBytes(bytes, flush: false);
    } catch (error) {
      talker.warning('GCodeStructure: falha ao gravar cache: $error');
    }
  }

  static Future<GCodeStructure> _decodeInIsolate(Uint8List bytes) async {
    try {
      return await Isolate.run(() => GCodeStructureCodec.decode(bytes));
    } catch (_) {
      return GCodeStructureCodec.decode(bytes);
    }
  }

  static String _fnv1a(String input) {
    var hash = 0x811c9dc5;
    for (final unit in input.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }
}

class _GCodeStructureProviderFamily {
  AsyncNotifierProvider<GCodeStructureNotifier, GCodeStructure> call(String machineUUID, GCodeFile file) =>
      _family((machineUUID, file));

  static final _family = AsyncNotifierProvider.family<GCodeStructureNotifier, GCodeStructure, (String, GCodeFile)>(
    GCodeStructureNotifier.new,
    name: 'gcodeStructure',
  );
}

/// Estrutura do G-code (cache → download → análise) usada pelo preview.
final gcodeStructureProvider = _GCodeStructureProviderFamily();
