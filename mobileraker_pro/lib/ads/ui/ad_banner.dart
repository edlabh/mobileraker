/*
 * Copyright (c) 2024-2026. Patrick Schmidt.
 * All rights reserved.
 */

import 'package:flutter/material.dart';

import '../ad_block_unit.dart';

/// Banner de anúncio inline adaptativo.
///
/// Stub local: não renderiza nada (ocupa zero espaço).
class InlineAdaptiveAdBanner extends StatelessWidget {
  const InlineAdaptiveAdBanner({
    super.key,
    required this.unit,
    this.constraints,
    this.animated = false,
    this.placeholder = false,
  });

  final AdBlockUnit unit;
  final BoxConstraints? constraints;
  final bool animated;
  final bool placeholder;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
