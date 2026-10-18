/*
 * Copyright (c) 2024-2026. Patrick Schmidt.
 * All rights reserved.
 */

import 'package:flutter/material.dart';

/// Botão que abre o formulário de privacidade/consentimento de anúncios.
///
/// Stub local: fica desabilitado — a página de configurações só o exibe
/// quando `isConsentFormAvailableProvider.value == true` (sempre `false`
/// neste build).
class DataAndPrivacyTextButton extends StatelessWidget {
  const DataAndPrivacyTextButton({super.key});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: null,
      child: const Text('Data & Privacy'),
    );
  }
}
