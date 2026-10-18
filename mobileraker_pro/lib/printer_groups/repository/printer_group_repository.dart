/*
 * Copyright (c) 2024-2026. Patrick Schmidt.
 * All rights reserved.
 */

import '../data/model/printer_group.dart';

/// Contrato do repositório de grupos de impressoras.
abstract class PrinterGroupRepository {
  Future<List<PrinterGroup>> findAll();

  Future<void> save(PrinterGroup group);

  Future<void> delete(PrinterGroup group);
}
