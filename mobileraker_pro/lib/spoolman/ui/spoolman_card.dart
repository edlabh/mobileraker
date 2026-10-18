/*
 * Copyright (c) 2024-2026. Patrick Schmidt.
 * All rights reserved.
 */

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../service/spoolman_service.dart';

/// Card de dashboard do Spoolman.
///
/// Mostra o carretel ativo (definido na página do Spoolman) e quanto resta
/// dele; sem servidor real os dados vêm do store em memória do stub.
class SpoolmanCard extends ConsumerWidget {
  const SpoolmanCard({super.key, required this.machineUUID});

  final String machineUUID;

  static Widget preview() => const SpoolmanCard(machineUUID: 'preview');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeSpool = ref.watch(activeSpoolProvider(machineUUID)).value;
    final remaining = activeSpool?.remainingWeight;
    final subtitle = switch (activeSpool) {
      null => 'Nenhum carretel ativo',
      _ when remaining != null => 'Carretel #${activeSpool.id} · ${remaining.toStringAsFixed(0)} g restantes',
      _ => 'Carretel #${activeSpool.id}',
    };

    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: const Icon(Icons.inventory_2_outlined),
        title: const Text('Spoolman'),
        subtitle: Text(subtitle),
      ),
    );
  }
}
