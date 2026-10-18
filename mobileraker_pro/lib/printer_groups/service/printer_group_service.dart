/*
 * Copyright (c) 2024-2026. Patrick Schmidt.
 * All rights reserved.
 */

import 'package:hive_ce/hive.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../data/model/printer_group.dart';

final printerGroupServiceProvider = Provider<PrinterGroupService>(
  (ref) => PrinterGroupService(ref),
);

/// Todos os grupos de impressoras salvos.
final printerGroupsProvider = FutureProvider<List<PrinterGroup>>(
  (ref) => ref.watch(printerGroupServiceProvider).all(),
);

/// Serviço de grupos de impressoras, persistidos no box Hive
/// `printer_groups` (aberto pelo app durante o setup).
class PrinterGroupService {
  PrinterGroupService(this._ref);

  final Ref _ref;

  static const String _boxName = 'printer_groups';

  Box<PrinterGroup>? get _box =>
      Hive.isBoxOpen(_boxName) ? Hive.box<PrinterGroup>(_boxName) : null;

  /// O box já é aberto pelo app no setup; nada a fazer aqui.
  Future<void> initialize() async {}

  Future<List<PrinterGroup>> all() async {
    return _box?.values.toList(growable: false) ?? const <PrinterGroup>[];
  }

  Future<void> save(PrinterGroup group) async {
    await _box?.put(group.uuid, group);
    _ref.invalidate(printerGroupsProvider);
  }

  Future<void> delete(PrinterGroup group) async {
    await _box?.delete(group.uuid);
    _ref.invalidate(printerGroupsProvider);
  }
}
