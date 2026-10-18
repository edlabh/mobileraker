/*
 * Copyright (c) 2024-2026. Patrick Schmidt.
 * All rights reserved.
 */

import 'package:common/data/model/hive/dashboard_component.dart';
import 'package:common/data/model/hive/dashboard_component_type.dart';
import 'package:common/data/model/hive/dashboard_layout.dart';
import 'package:common/data/model/hive/dashboard_tab.dart';
import 'package:hive_ce/hive.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Provider do serviço que gerencia os layouts de dashboard.
final dashboardLayoutServiceProvider = Provider<DashboardLayoutService>(
  (ref) => DashboardLayoutService(ref),
);

/// Layout efetivo de uma impressora.
///
/// Stub local: lê o layout salvo no box `dashboard_layouts` sob a chave
/// `machineUUID` (salvo por [DashboardLayoutService.saveDashboardLayoutForMachine])
/// e cai para o layout padrão quando não há nada salvo.
class _DashboardLayoutForMachineFamily {
  FutureProvider<DashboardLayout> call(String machineUUID) => _family(machineUUID);

  static final _family = FutureProvider.family<DashboardLayout, String>(
    (ref, machineUUID) => ref.watch(dashboardLayoutServiceProvider).dashboardLayoutForMachine(machineUUID),
  );
}

final dashboardLayoutForMachineProvider = _DashboardLayoutForMachineFamily();

class DashboardLayoutService {
  DashboardLayoutService(this._ref) {
    _ref.onDispose(dispose);
  }

  final Ref _ref;

  static const String _boxName = 'dashboard_layouts';

  Box<DashboardLayout>? get _box => Hive.isBoxOpen(_boxName) ? Hive.box<DashboardLayout>(_boxName) : null;

  /// Layout padrão definido pela Mobileraker.
  DashboardLayout defaultDashboardLayout() {
    return DashboardLayout(
      uuid: 'default',
      name: 'Default',
      tabs: [
        DashboardTab.create(
          name: 'General',
          icon: 'nozzle',
          components: [
            DashboardComponent.create(type: DashboardComponentType.machineStatus),
            DashboardComponent.create(type: DashboardComponentType.temperatureSensorPreset),
            DashboardComponent.create(type: DashboardComponentType.webcam),
            DashboardComponent.create(type: DashboardComponentType.controlXYZ),
            DashboardComponent.create(type: DashboardComponentType.zOffset),
            DashboardComponent.create(type: DashboardComponentType.spoolman),
          ],
        ),
        DashboardTab.create(
          name: 'Control',
          icon: 'sliders',
          components: [
            DashboardComponent.create(type: DashboardComponentType.macroGroup),
            DashboardComponent.create(type: DashboardComponentType.controlExtruder),
            DashboardComponent.create(type: DashboardComponentType.fans),
            DashboardComponent.create(type: DashboardComponentType.pins),
            DashboardComponent.create(type: DashboardComponentType.powerApi),
            DashboardComponent.create(type: DashboardComponentType.groupedSliders),
            DashboardComponent.create(type: DashboardComponentType.bedMesh),
          ],
        ),
      ],
    );
  }

  /// Layout vazio com duas abas vazias.
  DashboardLayout emptyDashboardLayout() {
    return DashboardLayout(
      uuid: 'default',
      name: 'Empty',
      tabs: [
        emptyDashboardTab('nozzle'),
        emptyDashboardTab('sliders'),
      ],
    );
  }

  /// Aba vazia.
  DashboardTab emptyDashboardTab([String icon = 'nozzle']) {
    return DashboardTab.create(name: 'Empty', icon: icon, components: const []);
  }

  DashboardLayout importFromJson(Map<String, dynamic> json) {
    try {
      return DashboardLayout.fromJson(json);
    } catch (_) {
      return defaultDashboardLayout();
    }
  }

  Future<DashboardLayout> dashboardLayoutForMachine(String machineUUID) async {
    final stored = _box?.get(machineUUID);
    return stored ?? defaultDashboardLayout();
  }

  Future<DashboardLayout> fetchDashboardLayoutForMachine(String machineUUID) =>
      dashboardLayoutForMachine(machineUUID);

  Future<void> saveDashboardLayoutForMachine(String machineUUID, DashboardLayout layout) async {
    final box = _box;
    if (box == null) return;
    final now = DateTime.now();
    await box.put(
      machineUUID,
      layout.copyWith(
        uuid: machineUUID,
        created: layout.created ?? now,
        lastModified: now,
      ),
    );
  }

  Future<List<DashboardLayout>> availableLayouts() async {
    return _box?.values.toList(growable: false) ?? const <DashboardLayout>[];
  }

  Future<void> persistLayout(DashboardLayout layout) async {
    final box = _box;
    if (box == null) return;
    await box.put(layout.uuid, layout);
  }

  Future<void> removeLayout(DashboardLayout layout) async {
    final box = _box;
    if (box == null || !box.containsKey(layout.uuid)) return;
    await box.delete(layout.uuid);
  }

  bool validateLayout(DashboardLayout layout, [bool throwIfError = false]) {
    // A barra de abas suporta entre 2 e 5 abas.
    final isValid = layout.tabs.length >= 2 && layout.tabs.length <= 5;
    if (!isValid && throwIfError) {
      throw ArgumentError('O dashboard precisa ter entre 2 e 5 abas.');
    }
    return isValid;
  }

  void dispose() {}
}
