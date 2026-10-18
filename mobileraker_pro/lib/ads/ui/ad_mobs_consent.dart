/*
 * Copyright (c) 2024-2026. Patrick Schmidt.
 * All rights reserved.
 */

import 'package:flutter/material.dart';

/// Wrapper do fluxo de consentimento de anúncios (UMP).
///
/// Stub local: repassa o `child` sem qualquer diálogo de consentimento.
class AdMobsConsent extends StatelessWidget {
  const AdMobsConsent({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}
