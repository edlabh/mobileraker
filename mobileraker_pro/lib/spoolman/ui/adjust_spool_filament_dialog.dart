/*
 * Copyright (c) 2024-2026. Patrick Schmidt.
 * All rights reserved.
 */

import 'package:common/service/ui/dialog_service_interface.dart';
import 'package:flutter/material.dart';

/// Diálogo para informar quanto filamento foi consumido do carretel.
///
/// Retorna `(amount, 'g')` ou `(amount, 'mm')` via [DialogResponse.confirmed],
/// conforme o contrato esperado pelo app.
class AdjustSpoolFilamentDialog extends StatefulWidget {
  const AdjustSpoolFilamentDialog({
    super.key,
    required this.request,
    required this.completer,
  });

  final DialogRequest request;
  final DialogCompleter completer;

  @override
  State<AdjustSpoolFilamentDialog> createState() => _AdjustSpoolFilamentDialogState();
}

class _AdjustSpoolFilamentDialogState extends State<AdjustSpoolFilamentDialog> {
  final TextEditingController _controller = TextEditingController();
  String _unit = 'g';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double? get _amount => double.tryParse(_controller.text.replaceAll(',', '.'));

  void _submit() {
    final amount = _amount;
    if (amount == null || amount <= 0) return;
    widget.completer(DialogResponse.confirmed((amount, _unit)));
  }

  @override
  Widget build(BuildContext context) {
    final amount = _amount;
    final canSubmit = amount != null && amount > 0;
    return AlertDialog(
      title: const Text('Consumir filamento'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Informe a quantidade de filamento consumida para ajustar o carretel.'),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(labelText: 'Quantidade'),
          ),
          const SizedBox(height: 12),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'g', label: Text('Gramas (g)')),
              ButtonSegment(value: 'mm', label: Text('Milímetros (mm)')),
            ],
            selected: {_unit},
            onSelectionChanged: (selection) => setState(() => _unit = selection.first),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => widget.completer(DialogResponse.aborted()),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: canSubmit ? _submit : null,
          child: const Text('Consumir'),
        ),
      ],
    );
  }
}
