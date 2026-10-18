/*
 * Copyright (c) 2024-2026. Patrick Schmidt.
 * All rights reserved.
 */

import 'package:common/ui/theme/theme_pack.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart' show Brightness, Color, ThemeData;
import 'package:hive_ce/hive.dart';

import 'custom_theme_config.dart';

const Object _unset = Object();

/// Tema customizado criado pelo usuário (config clara + opcional escura).
class CustomThemePack {
  const CustomThemePack({
    required this.uuid,
    required this.name,
    required this.lightConfig,
    this.darkConfig,
    this.logoPath,
    this.logoDarkPath,
  });

  factory CustomThemePack.fromJson(Map<String, dynamic> json) {
    final lightConfig = json['lightConfig'];
    final darkConfig = json['darkConfig'];
    return CustomThemePack(
      uuid: json['uuid'] as String? ?? '',
      name: json['name'] as String? ?? '',
      lightConfig: CustomThemeConfig.fromJson(
        lightConfig is Map ? lightConfig.cast<String, dynamic>() : const <String, dynamic>{},
      ),
      darkConfig: darkConfig is Map
          ? CustomThemeConfig.fromJson(darkConfig.cast<String, dynamic>())
          : null,
      logoPath: json['logoPath'] as String?,
      logoDarkPath: json['logoDarkPath'] as String?,
    );
  }

  final String uuid;
  final String name;
  final CustomThemeConfig lightConfig;
  final CustomThemeConfig? darkConfig;
  final String? logoPath;
  final String? logoDarkPath;

  Map<String, dynamic> toJson() => {
        'uuid': uuid,
        'name': name,
        'lightConfig': lightConfig.toJson(),
        'darkConfig': darkConfig?.toJson(),
        'logoPath': logoPath,
        'logoDarkPath': logoDarkPath,
      };

  /// `logoPath`/`logoDarkPath` aceitam `null` explícito para limpar o valor
  /// (ex.: `pack.copyWith(logoPath: null)`), por isso usam sentinela.
  CustomThemePack copyWith({
    String? uuid,
    String? name,
    CustomThemeConfig? lightConfig,
    CustomThemeConfig? darkConfig,
    Object? logoPath = _unset,
    Object? logoDarkPath = _unset,
  }) {
    return CustomThemePack(
      uuid: uuid ?? this.uuid,
      name: name ?? this.name,
      lightConfig: lightConfig ?? this.lightConfig,
      darkConfig: darkConfig ?? this.darkConfig,
      logoPath: identical(logoPath, _unset) ? this.logoPath : logoPath as String?,
      logoDarkPath: identical(logoDarkPath, _unset) ? this.logoDarkPath : logoDarkPath as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomThemePack &&
          runtimeType == other.runtimeType &&
          uuid == other.uuid &&
          name == other.name &&
          lightConfig == other.lightConfig &&
          darkConfig == other.darkConfig &&
          logoPath == other.logoPath &&
          logoDarkPath == other.logoDarkPath;

  @override
  int get hashCode => Object.hash(uuid, name, lightConfig, darkConfig, logoPath, logoDarkPath);
}

/// Índices do editor (app) → modos de superfície do `flex_color_scheme`.
/// Rótulos do editor: 0 "Level (uniform)", 1 "Low scaffold blend",
/// 2 "High scaffold blend", 3 "High surface, low scaffold",
/// 4 "High scaffold, low surface".
const List<FlexSurfaceMode> _kSurfaceModes = [
  FlexSurfaceMode.level,
  FlexSurfaceMode.levelSurfacesLowScaffold,
  FlexSurfaceMode.highScaffoldLevelSurface,
  FlexSurfaceMode.highSurfaceLowScaffold,
  FlexSurfaceMode.highScaffoldLowSurfaces,
];

/// Índices do editor (app) → estilos de AppBar do `flex_color_scheme`.
/// Rótulos do editor: 0 Surface, 1 Primary, 2 Material default,
/// 3 Background, 4 Scaffold background (default).
const List<FlexAppBarStyle> _kAppBarStyles = [
  FlexAppBarStyle.surface,
  FlexAppBarStyle.primary,
  FlexAppBarStyle.material,
  FlexAppBarStyle.background,
  FlexAppBarStyle.scaffoldBackground,
];

int _clampIndex(int index, int length) => index < 0 ? 0 : (index >= length ? length - 1 : index);

/// Constrói um [ThemePack] a partir de um [CustomThemePack] usando
/// `flex_color_scheme` — a mesma base dos pacotes de tema embutidos do app.
ThemePack buildThemePack(CustomThemePack pack) {
  final darkConfig = pack.darkConfig ?? pack.lightConfig;
  return ThemePack(
    name: pack.name,
    lightTheme: _themeFromConfig(pack.lightConfig, Brightness.light),
    darkTheme: _themeFromConfig(darkConfig, Brightness.dark),
  );
}

ThemeData _themeFromConfig(CustomThemeConfig config, Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final primary = Color(config.primaryColor);
  final secondary = config.secondaryColor != null ? Color(config.secondaryColor!) : primary;
  final tertiary = config.tertiaryColor != null ? Color(config.tertiaryColor!) : primary;
  final appBarColor = config.appBarColor != null ? Color(config.appBarColor!) : null;

  final colors = FlexSchemeColor(
    primary: primary,
    secondary: secondary,
    tertiary: tertiary,
    appBarColor: appBarColor ?? primary,
  );
  final surfaceMode = _kSurfaceModes[_clampIndex(config.surfaceModeIndex, _kSurfaceModes.length)];
  final appBarStyle = appBarColor != null
      ? FlexAppBarStyle.custom
      : _kAppBarStyles[_clampIndex(config.appBarStyleIndex, _kAppBarStyles.length)];

  final theme = isDark
      ? FlexThemeData.dark(
          colors: colors,
          surfaceMode: surfaceMode,
          blendLevel: config.blendLevel,
          appBarStyle: appBarStyle,
          usedColors: config.usedColors,
          darkIsTrueBlack: config.darkIsTrueBlack,
          fontFamily: config.fontFamily,
          useMaterial3: config.useMaterial3,
        )
      : FlexThemeData.light(
          colors: colors,
          surfaceMode: surfaceMode,
          blendLevel: config.blendLevel,
          appBarStyle: appBarStyle,
          usedColors: config.usedColors,
          lightIsWhite: config.lightIsWhite,
          fontFamily: config.fontFamily,
          useMaterial3: config.useMaterial3,
        );

  // Superfícies escolhidas manualmente no editor sobrepõem o esquema gerado.
  if (config.surfaceColor != null || config.onSurfaceColor != null) {
    return theme.copyWith(
      colorScheme: theme.colorScheme.copyWith(
        surface: config.surfaceColor != null ? Color(config.surfaceColor!) : null,
        onSurface: config.onSurfaceColor != null ? Color(config.onSurfaceColor!) : null,
      ),
    );
  }
  return theme;
}

/// Adapter Hive (typeId 19).
class CustomThemePackAdapter extends TypeAdapter<CustomThemePack> {
  @override
  final int typeId = 19;

  @override
  CustomThemePack read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CustomThemePack(
      uuid: fields[0] as String? ?? '',
      name: fields[1] as String? ?? '',
      lightConfig: fields[2] as CustomThemeConfig? ??
          const CustomThemeConfig(primaryColor: 0),
      darkConfig: fields[3] as CustomThemeConfig?,
      logoPath: fields[4] as String?,
      logoDarkPath: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, CustomThemePack obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.uuid)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.lightConfig)
      ..writeByte(3)
      ..write(obj.darkConfig)
      ..writeByte(4)
      ..write(obj.logoPath)
      ..writeByte(5)
      ..write(obj.logoDarkPath);
  }
}
