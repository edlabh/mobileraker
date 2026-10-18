/*
 * Copyright (c) 2023-2026. Patrick Schmidt.
 * All rights reserved.
 */

import 'package:flutter/material.dart';

/// Exibe um par título/valor nas páginas do Spoolman.
class PropertyWithTitle extends StatelessWidget {
  const PropertyWithTitle({
    super.key,
    required this.title,
    required this.property,
  });

  factory PropertyWithTitle.text({
    Key? key,
    required String title,
    required String property,
  }) {
    return PropertyWithTitle(title: title, property: Text(property));
  }

  final String title;
  final Widget property;

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(title, style: themeData.textTheme.bodyMedium),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DefaultTextStyle(
              style: themeData.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500) ??
                  const TextStyle(fontWeight: FontWeight.w500),
              child: property,
            ),
          ),
        ],
      ),
    );
  }
}
