/*
 * Copyright (c) 2024-2026. Patrick Schmidt.
 * All rights reserved.
 */

import 'package:hive_ce/hive.dart';

/// Configuração de cores/fonte de um tema customizado (claro ou escuro).
class CustomThemeConfig {
  const CustomThemeConfig({
    required this.primaryColor,
    this.secondaryColor,
    this.tertiaryColor,
    this.surfaceColor,
    this.onSurfaceColor,
    this.appBarColor,
    this.useMaterial3 = true,
    this.fontFamily,
    this.blendLevel = 0,
    this.surfaceModeIndex = 0,
    this.appBarStyleIndex = 4,
    this.usedColors = 1,
    this.lightIsWhite = false,
    this.darkIsTrueBlack = false,
  });

  factory CustomThemeConfig.fromJson(Map<String, dynamic> json) {
    return CustomThemeConfig(
      primaryColor: json['primaryColor'] as int? ?? 0,
      secondaryColor: json['secondaryColor'] as int?,
      tertiaryColor: json['tertiaryColor'] as int?,
      surfaceColor: json['surfaceColor'] as int?,
      onSurfaceColor: json['onSurfaceColor'] as int?,
      appBarColor: json['appBarColor'] as int?,
      useMaterial3: json['useMaterial3'] as bool? ?? true,
      fontFamily: json['fontFamily'] as String?,
      blendLevel: json['blendLevel'] as int? ?? 0,
      surfaceModeIndex: json['surfaceModeIndex'] as int? ?? 0,
      appBarStyleIndex: json['appBarStyleIndex'] as int? ?? 4,
      usedColors: json['usedColors'] as int? ?? 1,
      lightIsWhite: json['lightIsWhite'] as bool? ?? false,
      darkIsTrueBlack: json['darkIsTrueBlack'] as bool? ?? false,
    );
  }

  /// Valor ARGB32 da cor primária.
  final int primaryColor;
  final int? secondaryColor;
  final int? tertiaryColor;
  final int? surfaceColor;
  final int? onSurfaceColor;
  final int? appBarColor;
  final bool useMaterial3;
  final String? fontFamily;
  final int blendLevel;
  final int surfaceModeIndex;
  final int appBarStyleIndex;
  final int usedColors;
  final bool lightIsWhite;
  final bool darkIsTrueBlack;

  Map<String, dynamic> toJson() => {
        'primaryColor': primaryColor,
        'secondaryColor': secondaryColor,
        'tertiaryColor': tertiaryColor,
        'surfaceColor': surfaceColor,
        'onSurfaceColor': onSurfaceColor,
        'appBarColor': appBarColor,
        'useMaterial3': useMaterial3,
        'fontFamily': fontFamily,
        'blendLevel': blendLevel,
        'surfaceModeIndex': surfaceModeIndex,
        'appBarStyleIndex': appBarStyleIndex,
        'usedColors': usedColors,
        'lightIsWhite': lightIsWhite,
        'darkIsTrueBlack': darkIsTrueBlack,
      };

  CustomThemeConfig copyWith({
    int? primaryColor,
    int? secondaryColor,
    int? tertiaryColor,
    int? surfaceColor,
    int? onSurfaceColor,
    int? appBarColor,
    bool? useMaterial3,
    String? fontFamily,
    int? blendLevel,
    int? surfaceModeIndex,
    int? appBarStyleIndex,
    int? usedColors,
    bool? lightIsWhite,
    bool? darkIsTrueBlack,
  }) {
    return CustomThemeConfig(
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      tertiaryColor: tertiaryColor ?? this.tertiaryColor,
      surfaceColor: surfaceColor ?? this.surfaceColor,
      onSurfaceColor: onSurfaceColor ?? this.onSurfaceColor,
      appBarColor: appBarColor ?? this.appBarColor,
      useMaterial3: useMaterial3 ?? this.useMaterial3,
      fontFamily: fontFamily ?? this.fontFamily,
      blendLevel: blendLevel ?? this.blendLevel,
      surfaceModeIndex: surfaceModeIndex ?? this.surfaceModeIndex,
      appBarStyleIndex: appBarStyleIndex ?? this.appBarStyleIndex,
      usedColors: usedColors ?? this.usedColors,
      lightIsWhite: lightIsWhite ?? this.lightIsWhite,
      darkIsTrueBlack: darkIsTrueBlack ?? this.darkIsTrueBlack,
    );
  }
}

/// Adapter Hive (typeId 18 — verifique os ids já usados pelo `common`).
class CustomThemeConfigAdapter extends TypeAdapter<CustomThemeConfig> {
  @override
  final int typeId = 18;

  @override
  CustomThemeConfig read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CustomThemeConfig(
      primaryColor: fields[0] as int? ?? 0,
      secondaryColor: fields[1] as int?,
      tertiaryColor: fields[2] as int?,
      surfaceColor: fields[3] as int?,
      onSurfaceColor: fields[4] as int?,
      appBarColor: fields[5] as int?,
      useMaterial3: fields[6] as bool? ?? true,
      fontFamily: fields[7] as String?,
      blendLevel: fields[8] as int? ?? 0,
      surfaceModeIndex: fields[9] as int? ?? 0,
      appBarStyleIndex: fields[10] as int? ?? 4,
      usedColors: fields[11] as int? ?? 1,
      lightIsWhite: fields[12] as bool? ?? false,
      darkIsTrueBlack: fields[13] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, CustomThemeConfig obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.primaryColor)
      ..writeByte(1)
      ..write(obj.secondaryColor)
      ..writeByte(2)
      ..write(obj.tertiaryColor)
      ..writeByte(3)
      ..write(obj.surfaceColor)
      ..writeByte(4)
      ..write(obj.onSurfaceColor)
      ..writeByte(5)
      ..write(obj.appBarColor)
      ..writeByte(6)
      ..write(obj.useMaterial3)
      ..writeByte(7)
      ..write(obj.fontFamily)
      ..writeByte(8)
      ..write(obj.blendLevel)
      ..writeByte(9)
      ..write(obj.surfaceModeIndex)
      ..writeByte(10)
      ..write(obj.appBarStyleIndex)
      ..writeByte(11)
      ..write(obj.usedColors)
      ..writeByte(12)
      ..write(obj.lightIsWhite)
      ..writeByte(13)
      ..write(obj.darkIsTrueBlack);
  }
}
