/*
 * Copyright (c) 2024-2026. Patrick Schmidt.
 * All rights reserved.
 */

import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../data/model/printer_group.dart';
import '../repository/printer_group_repository.dart';
import '../repository/printer_group_repository_impl.dart';

final printerGroupServiceProvider = Provider<PrinterGroupService>(
  (ref) => PrinterGroupService(ref),
);

/// Todos os grupos de impressoras salvos.
final printerGroupsProvider = FutureProvider<List<PrinterGroup>>(
  (ref) => ref.watch(printerGroupServiceProvider).all(),
);

/// Serviço de grupos de impressoras (persistidos via [PrinterGroupRepository]).
class PrinterGroupService {
  PrinterGroupService(this._ref);

  final Ref _ref;

  PrinterGroupRepository get _repository => _ref.read(printerGroupRepositoryProvider);

  /// O box já é aberto pelo app no setup; nada a fazer aqui.
  Future<void> initialize() async {}

  Future<List<PrinterGroup>> all() => _repository.findAll();

  Future<void> save(PrinterGroup group) async {
    await _repository.save(group);
    _ref.invalidate(printerGroupsProvider);
  }

  Future<void> delete(PrinterGroup group) async {
    await _repository.delete(group);
    _ref.invalidate(printerGroupsProvider);
  }
}
