/*
 * Copyright (c) 2024-2026. Patrick Schmidt.
 * All rights reserved.
 */

import 'package:hive_ce/hive.dart';
import 'package:uuid/uuid.dart';

const Object _unset = Object();

/// Preset de pré-aquecimento de um grupo de impressoras.
class GroupPreset {
  const GroupPreset({
    required this.uuid,
    required this.name,
    this.extruderTemp = 0,
    this.bedTemp = 0,
    this.customGCode,
  });

  factory GroupPreset.create({
    required String name,
    int extruderTemp = 0,
    int bedTemp = 0,
    String? customGCode,
  }) {
    return GroupPreset(
      uuid: const Uuid().v4(),
      name: name,
      extruderTemp: extruderTemp,
      bedTemp: bedTemp,
      customGCode: customGCode,
    );
  }

  final String uuid;
  final String name;
  final int extruderTemp;
  final int bedTemp;
  final String? customGCode;

  /// `customGCode` aceita `null` explícito para limpar o valor, por isso usa
  /// sentinela.
  GroupPreset copyWith({
    String? uuid,
    String? name,
    int? extruderTemp,
    int? bedTemp,
    Object? customGCode = _unset,
  }) {
    return GroupPreset(
      uuid: uuid ?? this.uuid,
      name: name ?? this.name,
      extruderTemp: extruderTemp ?? this.extruderTemp,
      bedTemp: bedTemp ?? this.bedTemp,
      customGCode: identical(customGCode, _unset) ? this.customGCode : customGCode as String?,
    );
  }
}

/// Adapter Hive (typeId 20 — ids 1-17 são usados pelo pacote `common`).
class GroupPresetAdapter extends TypeAdapter<GroupPreset> {
  @override
  final int typeId = 20;

  @override
  GroupPreset read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GroupPreset(
      uuid: fields[0] as String? ?? '',
      name: fields[1] as String? ?? '',
      extruderTemp: fields[2] as int? ?? 0,
      bedTemp: fields[3] as int? ?? 0,
      customGCode: fields[4] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, GroupPreset obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.uuid)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.extruderTemp)
      ..writeByte(3)
      ..write(obj.bedTemp)
      ..writeByte(4)
      ..write(obj.customGCode);
  }
}
