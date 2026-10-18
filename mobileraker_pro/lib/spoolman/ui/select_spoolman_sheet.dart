/*
 * Copyright (c) 2024-2026. Patrick Schmidt.
 * All rights reserved.
 */

import 'package:common/util/logger.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../ui/components/qr_scanner.dart';
import '../dto/get_spool.dart';
import '../dto/spoolman_dto_mixin.dart';
import '../service/spoolman_service.dart';
import 'spool_list_entry.dart';
import 'spoolman_scroll_pagination.dart';

/// Bottom sheet de seleção do carretel ativo do Spoolman.
///
/// Duas abas: a lista de carretéis disponíveis e o scanner do QR-Code
/// (formato `web+spoolman:s-<id>`, o mesmo gerado pela página de detalhes).
class SelectSpoolmanSheet extends StatelessWidget {
  const SelectSpoolmanSheet({super.key, required this.machineUUID});

  final String machineUUID;

  @override
  Widget build(BuildContext context) => _SelectSpoolmanBottomSheet(machineUUID: machineUUID);
}

class _SelectSpoolmanController {
  _SelectSpoolmanController(this._ref, this.machineUUID);

  final Ref _ref;
  final String machineUUID;

  SpoolmanService get _spoolmanService => _ref.read(spoolmanServiceProvider(machineUUID));

  Future<void> setActiveSpool(GetSpool spool) => _spoolmanService.setActiveSpool(spool);

  Future<GetSpool?> spoolById(int id) => _ref.read(spoolProvider(machineUUID, id).future);
}

final _selectSpoolmanControllerProvider = Provider.family<_SelectSpoolmanController, String>(
  (ref, machineUUID) => _SelectSpoolmanController(ref, machineUUID),
);

class _SelectSpoolmanBottomSheet extends StatelessWidget {
  const _SelectSpoolmanBottomSheet({required this.machineUUID});

  final String machineUUID;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Material(
        type: MaterialType.transparency,
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.6,
          child: DefaultTabController(
            length: 2,
            child: Column(
              children: [
                const _SheetHeader(),
                Expanded(
                  child: TabBarView(
                    children: [
                      _AvailableSpoolsList(machineUUID: machineUUID),
                      _ScanSpoolQr(machineUUID: machineUUID),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader();

  @override
  Widget build(BuildContext context) {
    return TabBar(
      tabs: [
        Tab(text: 'select_spool.header.spools'.tr()),
        Tab(text: 'select_spool.header.qr'.tr()),
      ],
    );
  }
}

class _AvailableSpoolsList extends ConsumerWidget {
  const _AvailableSpoolsList({required this.machineUUID});

  final String machineUUID;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(_selectSpoolmanControllerProvider(machineUUID));
    return SpoolmanScrollPagination(
      machineUUID: machineUUID,
      type: SpoolmanListType.spools,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      onEntryTap: (SpoolmanIdentifiableDtoMixin dto) async {
        if (dto is! GetSpool) return;
        await controller.setActiveSpool(dto);
        if (context.mounted) Navigator.of(context).pop();
      },
    );
  }
}

class _ScanSpoolQr extends ConsumerStatefulWidget {
  const _ScanSpoolQr({required this.machineUUID});

  final String machineUUID;

  @override
  ConsumerState<_ScanSpoolQr> createState() => _ScanSpoolQrState();
}

class _ScanSpoolQrState extends ConsumerState<_ScanSpoolQr> {
  /// QR-Codes do Spoolman têm o formato `web+spoolman:s-<id>`.
  static final RegExp _spoolmanQrPattern = RegExp(r'web\+spoolman:s-(\d+)');

  bool _loading = false;
  GetSpool? _spool;
  int? _notFoundId;
  Object? _qrError;

  void _onDetected(String code) {
    final match = _spoolmanQrPattern.firstMatch(code);
    final id = match == null ? null : int.tryParse(match.group(1)!);
    if (id == null) {
      // Não é um QR-Code do Spoolman — continua escaneando.
      return;
    }
    talker.info('Found spoolman QR code with id $id');
    _loadSpool(id);
  }

  Future<void> _loadSpool(int id) async {
    setState(() {
      _loading = true;
      _spool = null;
      _notFoundId = null;
      _qrError = null;
    });
    final controller = ref.read(_selectSpoolmanControllerProvider(widget.machineUUID));
    try {
      final spool = await controller.spoolById(id);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _spool = spool;
        _notFoundId = spool == null ? id : null;
      });
    } catch (error, stackTrace) {
      talker.error('Error while loading spool from QR code', error, stackTrace);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _notFoundId = id;
      });
    }
  }

  void _scanAgain() {
    setState(() {
      _loading = false;
      _spool = null;
      _notFoundId = null;
      _qrError = null;
    });
  }

  Future<void> _setActive() async {
    final spool = _spool;
    if (spool == null) return;
    final controller = ref.read(_selectSpoolmanControllerProvider(widget.machineUUID));
    await controller.setActiveSpool(spool);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final spool = _spool;
    if (spool != null) {
      return Column(
        children: [
          const SizedBox(height: 8),
          SpoolListEntry(spool: spool),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilledButton.tonalIcon(
                onPressed: _setActive,
                icon: const Icon(Icons.check),
                label: Text('select_spool.set_active'.tr()),
              ),
              const SizedBox(width: 12),
              TextButton.icon(
                onPressed: _scanAgain,
                icon: const Icon(Icons.qr_code_scanner),
                label: Text('select_spool.scan_again'.tr()),
              ),
            ],
          ),
        ],
      );
    }

    final notFoundId = _notFoundId;
    if (notFoundId != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.search_off, size: 36),
              const SizedBox(height: 8),
              Text(
                'select_spool.spool_id_not_found'.tr(args: ['$notFoundId']),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _scanAgain,
                icon: const Icon(Icons.qr_code_scanner),
                label: Text('select_spool.scan_again'.tr()),
              ),
            ],
          ),
        ),
      );
    }

    final qrError = _qrError;
    if (qrError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 36),
              const SizedBox(height: 8),
              Text(
                'select_spool.qr_error'.tr(args: ['$qrError']),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _scanAgain,
                icon: const Icon(Icons.qr_code_scanner),
                label: Text('select_spool.scan_again'.tr()),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(14),
      child: QrScanner(
        onDetected: _onDetected,
        onError: (error) => setState(() => _qrError = error),
      ),
    );
  }
}
