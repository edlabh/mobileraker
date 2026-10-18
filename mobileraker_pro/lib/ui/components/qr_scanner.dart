/*
 * Copyright (c) 2024-2026. Patrick Schmidt.
 * All rights reserved.
 */

import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Leitor de QR-Code (usado para escanear o QR do carretel do Spoolman).
class QrScanner extends StatefulWidget {
  const QrScanner({super.key, required this.onDetected, this.onError});

  /// Chamado com o conteúdo do primeiro QR-Code lido.
  final void Function(String code) onDetected;

  /// Chamado quando o scanner falha (câmera indisponível, permissão etc.).
  final void Function(Object error)? onError;

  @override
  QrScannerState createState() => QrScannerState();
}

class QrScannerState extends State<QrScanner> {
  final MobileScannerController _controller = MobileScannerController();
  StreamSubscription<BarcodeCapture>? _subscription;
  bool _handled = false;

  @override
  void initState() {
    super.initState();
    _controller.start(cameraDirection: CameraFacing.back);
    _subscription = _controller.barcodes.listen(_onBarcode, onError: widget.onError);
  }

  void _onBarcode(BarcodeCapture capture) {
    if (_handled) return;
    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue;
      if (value == null || value.isEmpty) continue;
      _handled = true;
      widget.onDetected(value);
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: MobileScanner(
        controller: _controller,
        errorBuilder: (context, error) => _QrScannerMessage(
          icon: Icons.no_photography_outlined,
          message: error.errorDetails?.message ?? error.errorCode.name,
        ),
        placeholderBuilder: (context) => const _QrScannerMessage(
          icon: Icons.qr_code_scanner,
          message: 'bottom_sheets.select_spool.qr_loading',
        ),
      ),
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _controller.dispose();
    super.dispose();
  }
}

class _QrScannerMessage extends StatelessWidget {
  const _QrScannerMessage({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 36),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                message.tr(),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
