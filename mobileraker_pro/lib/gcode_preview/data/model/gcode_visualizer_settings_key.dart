/*
 * Copyright (c) 2024-2026. Patrick Schmidt.
 * All rights reserved.
 */

import 'package:common/service/setting_service.dart';

/// Chaves de configuração do visualizador de G-code.
enum GCodeVisualizerSettingsKey implements KeyValueStoreKey {
  showGrid('gcode_show_grid', true),
  showAxes('gcode_show_axes', true),
  showNextLayer('gcode_show_next_layer', true),
  showPreviousLayer('gcode_show_previous_layer', true),
  extrusionWidthMultiplier('gcode_extrusion_width_multiplier', 1.0),
  showExtrusion('gcode_show_extrusion', true),
  showRetraction('gcode_show_retraction', true),
  showTravel('gcode_show_travel', true);

  const GCodeVisualizerSettingsKey(this.key, [this.defaultValue]);

  @override
  final String key;
  @override
  final Object? defaultValue;
}
