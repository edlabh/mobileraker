/*
 * Copyright (c) 2024-2026. Patrick Schmidt.
 * All rights reserved.
 */

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Placeholder (shimmer) de um item da lista de fabricantes.
class VendorListEntryShimmer extends StatelessWidget {
  const VendorListEntryShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = theme.colorScheme.surfaceContainerHighest;
    final highlight = theme.colorScheme.surfaceContainerLow;
    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: ListTile(
        leading: CircleAvatar(backgroundColor: base),
        title: Align(
          alignment: Alignment.centerLeft,
          child: Container(
            height: 12,
            width: 120,
            decoration: BoxDecoration(
              color: base,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
      ),
    );
  }
}
