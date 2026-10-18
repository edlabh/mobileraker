/*
 * Copyright (c) 2024-2026. Patrick Schmidt.
 * All rights reserved.
 */

import 'package:flutter/material.dart';

import '../../data/model/custom_theme_pack.dart';
import 'custom_theme_color_swatch.dart';

class CustomThemeListTile extends StatelessWidget {
  const CustomThemeListTile({
    super.key,
    required this.pack,
    required this.onEdit,
    required this.onMore,
  });

  final CustomThemePack pack;
  final VoidCallback onEdit;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CustomThemeColorSwatch(pack: pack),
      title: Text(pack.name),
      onTap: onEdit,
      trailing: IconButton(
        icon: const Icon(Icons.more_vert),
        onPressed: onMore,
      ),
    );
  }
}
