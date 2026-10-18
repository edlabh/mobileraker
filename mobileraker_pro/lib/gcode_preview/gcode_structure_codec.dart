/*
 * Copyright (c) 2024-2026. Patrick Schmidt.
 * All rights reserved.
 */

import 'dart:typed_data';

import 'data/model/gcode_structure.dart';
import 'data/model/layer.dart';
import 'data/model/move.dart';

/// Serialização binária da estrutura do G-code (cache em disco).
///
/// Formato (little-endian):
///   header: magic(u32) version(u32) maxLayer(u32) layerCount(u32)
///   camada: z(f64) moveCount(u32)
///   movimento: startX(f32) startY(f32) endX(f32) endY(f32) extrusion(f32)
///              filePos(i32) flags(u8)
class GCodeStructureCodec {
  const GCodeStructureCodec._();

  static const int _magic = 0x4D475031; // 'MGP1'
  static const int _version = 1;

  static Uint8List encode(List<Layer> layers, int maxLayer) {
    var size = 16;
    for (final layer in layers) {
      size += 12 + layer.moves.length * 25;
    }
    final out = Uint8List(size);
    final data = ByteData.view(out.buffer);
    var o = 0;
    data.setUint32(o, _magic, Endian.little);
    o += 4;
    data.setUint32(o, _version, Endian.little);
    o += 4;
    data.setUint32(o, maxLayer, Endian.little);
    o += 4;
    data.setUint32(o, layers.length, Endian.little);
    o += 4;
    for (final layer in layers) {
      data.setFloat64(o, layer.z, Endian.little);
      o += 8;
      data.setUint32(o, layer.moves.length, Endian.little);
      o += 4;
      for (final move in layer.moves) {
        data.setFloat32(o, move.startX, Endian.little);
        o += 4;
        data.setFloat32(o, move.startY, Endian.little);
        o += 4;
        data.setFloat32(o, move.endX, Endian.little);
        o += 4;
        data.setFloat32(o, move.endY, Endian.little);
        o += 4;
        data.setFloat32(o, move.extrusion, Endian.little);
        o += 4;
        data.setInt32(o, move.filePos, Endian.little);
        o += 4;
        var flags = 0;
        if (move.isExtrusion) flags |= 1;
        if (move.isRetraction) flags |= 2;
        data.setUint8(o, flags);
        o += 1;
      }
    }
    return out;
  }

  static GCodeStructure decode(Uint8List bytes) {
    if (bytes.length < 16) throw const FormatException('Cache de preview inválido');
    final data = ByteData.view(bytes.buffer, bytes.offsetInBytes, bytes.length);
    var o = 0;
    final magic = data.getUint32(o, Endian.little);
    o += 4;
    if (magic != _magic) throw const FormatException('Cache de preview inválido');
    final version = data.getUint32(o, Endian.little);
    o += 4;
    if (version != _version) throw FormatException('Versão de cache incompatível ($version)');
    final maxLayer = data.getUint32(o, Endian.little);
    o += 4;
    final layerCount = data.getUint32(o, Endian.little);
    o += 4;
    if (layerCount > 1 << 22) throw const FormatException('Cache de preview corrompido');
    final layers = <Layer>[];
    for (var i = 0; i < layerCount; i++) {
      if (o + 12 > bytes.length) throw const FormatException('Cache de preview truncado');
      final z = data.getFloat64(o, Endian.little);
      o += 8;
      final moveCount = data.getUint32(o, Endian.little);
      o += 4;
      if (moveCount > 1 << 26 || o + moveCount * 25 > bytes.length) {
        throw const FormatException('Cache de preview truncado');
      }
      final moves = <Move>[];
      for (var k = 0; k < moveCount; k++) {
        final startX = data.getFloat32(o, Endian.little);
        o += 4;
        final startY = data.getFloat32(o, Endian.little);
        o += 4;
        final endX = data.getFloat32(o, Endian.little);
        o += 4;
        final endY = data.getFloat32(o, Endian.little);
        o += 4;
        final extrusion = data.getFloat32(o, Endian.little);
        o += 4;
        final filePos = data.getInt32(o, Endian.little);
        o += 4;
        o += 1; // flags (recalculadas a partir da extrusão)
        moves.add(Move(
          startX: startX,
          startY: startY,
          endX: endX,
          endY: endY,
          extrusion: extrusion,
          filePos: filePos,
        ));
      }
      layers.add(Layer(
        index: i,
        z: z,
        moves: moves,
        filePosStart: moves.isEmpty ? 0 : moves.first.filePos,
        filePosEnd: moves.isEmpty ? 0 : moves.last.filePos,
      ));
    }
    return GCodeStructure(layers: layers, maxLayer: maxLayer);
  }
}
