/*
 * Copyright (c) 2024-2026. Patrick Schmidt.
 * All rights reserved.
 */

import 'package:hive_ce/hive.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../data/model/printer_group.dart';
import 'printer_group_repository.dart';

final printerGroupRepositoryProvider = Provider<PrinterGroupRepository>(
  (ref) => PrinterGroupRepositoryImpl(),
);

/// Repositório dos grupos de impressoras, persistidos no box Hive
/// `printer_groups` (aberto pelo app durante o setup).
class PrinterGroupRepositoryImpl implements PrinterGroupRepository {
  static const String _boxName = 'printer_groups';

  Box<PrinterGroup>? get _box =>
      Hive.isBoxOpen(_boxName) ? Hive.box<PrinterGroup>(_boxName) : null;

  @override
  Future<List<PrinterGroup>> findAll() async {
    return _box?.values.toList(growable: false) ?? const <PrinterGroup>[];
  }

  @override
  Future<void> save(PrinterGroup group) async {
    await _box?.put(group.uuid, group);
  }

  @override
  Future<void> delete(PrinterGroup group) async {
    await _box?.delete(group.uuid);
  }
}
