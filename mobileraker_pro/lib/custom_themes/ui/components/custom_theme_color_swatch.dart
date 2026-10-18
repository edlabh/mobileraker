/*
 * Copyright (c) 2024-2026. Patrick Schmidt.
 * All rights reserved.
 */

import 'package:flutter/material.dart';

import '../../data/model/custom_theme_pack.dart';

/// Prévia das cores de um tema customizado (config clara e escura).
class CustomThemeColorSwatch extends StatelessWidget {
  const CustomThemeColorSwatch({super.key, required this.pack, this.dotSize = 10});

  final CustomThemePack pack;
  final double dotSize;

  @override
  Widget build(BuildContext context) {
    final light = pack.lightConfig;
    final dark = pack.darkConfig;

    final lightColors = <Color>[
      Color(light.primaryColor),
      if (light.secondaryColor != null) Color(light.secondaryColor!),
      if (light.tertiaryColor != null) Color(light.tertiaryColor!),
    ];
    final darkColors = <Color>[
      if (dark != null) Color(dark.primaryColor),
      if (dark?.secondaryColor != null) Color(dark!.secondaryColor!),
      if (dark?.tertiaryColor != null) Color(dark!.tertiaryColor!),
    ];

    return SizedBox(
      width: dotSize * 3 + 8,
      height: dotSize * 2 + 4,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _DotRow(colors: lightColors, size: dotSize),
          if (darkColors.isNotEmpty) ...[
            const SizedBox(height: 2),
            _DotRow(colors: darkColors, size: dotSize),
          ],
        ],
      ),
    );
  }
}

class _DotRow extends StatelessWidget {
  const _DotRow({required this.colors, required this.size});

  final List<Color> colors;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final color in colors)
          Container(
            width: size,
            height: size,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Theme.of(context).colorScheme.outlineVariant, width: 0.5),
            ),
          ),
      ],
    );
  }
}
