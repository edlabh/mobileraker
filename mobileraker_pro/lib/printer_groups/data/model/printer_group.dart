/*
 * Copyright (c) 2024-2026. Patrick Schmidt.
 * All rights reserved.
 */

import 'package:hive_ce/hive.dart';
import 'package:uuid/uuid.dart';

import 'group_preset.dart';

export 'group_preset.dart';

/// Grupo de impressoras — usado para ações em frota (pré-aquecer, imprimir
/// em várias impressoras, etc.).
class PrinterGroup {
  const PrinterGroup({
    required this.uuid,
    required this.name,
    required this.machineUUIDs,
    this.presets = const [],
  });

  factory PrinterGroup.create({
    required String name,
    required List<String> machineUUIDs,
    List<GroupPreset> presets = const [],
  }) {
    return PrinterGroup(
      uuid: const Uuid().v4(),
      name: name,
      machineUUIDs: machineUUIDs,
      presets: presets,
    );
  }

  final String uuid;
  final String name;
  final List<String> machineUUIDs;
  final List<GroupPreset> presets;

  bool get hasPresets => presets.isNotEmpty;

  PrinterGroup copyWith({
    String? uuid,
    String? name,
    List<String>? machineUUIDs,
    List<GroupPreset>? presets,
  }) {
    return PrinterGroup(
      uuid: uuid ?? this.uuid,
      name: name ?? this.name,
      machineUUIDs: machineUUIDs ?? this.machineUUIDs,
      presets: presets ?? this.presets,
    );
  }
}

/// Adapter Hive (typeId 21 — ids 1-17 são usados pelo pacote `common`).
class PrinterGroupAdapter extends TypeAdapter<PrinterGroup> {
  @override
  final int typeId = 21;

  @override
  PrinterGroup read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PrinterGroup(
      uuid: fields[0] as String? ?? '',
      name: fields[1] as String? ?? '',
      machineUUIDs: (fields[2] as List?)?.cast<String>() ?? const <String>[],
      presets: (fields[3] as List?)?.cast<GroupPreset>() ?? const <GroupPreset>[],
    );
  }

  @override
  void write(BinaryWriter writer, PrinterGroup obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.uuid)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.machineUUIDs)
      ..writeByte(3)
      ..write(obj.presets);
  }
}
