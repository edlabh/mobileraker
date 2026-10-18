/*
 * Copyright (c) 2024-2026. Patrick Schmidt.
 * All rights reserved.
 */

import 'package:flutter/material.dart';

/// Bottom sheet de seleção de algum item do Spoolman.
///
/// Stub local: a seleção depende do servidor Spoolman real; exibe apenas um
/// aviso de indisponibilidade.
class SelectSpoolmanSheet extends StatelessWidget {
  const SelectSpoolmanSheet({super.key, required this.machineUUID});

  final String machineUUID;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.inventory_2_outlined, size: 36),
          SizedBox(height: 8),
          Text(
            'Seleção do Spoolman indisponível neste build local (pro).',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
