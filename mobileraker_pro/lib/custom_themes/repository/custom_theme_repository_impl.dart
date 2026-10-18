/*
 * Copyright (c) 2024-2026. Patrick Schmidt.
 * All rights reserved.
 */

import 'package:hive_ce/hive.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../data/model/custom_theme_pack.dart';
import 'custom_theme_repository.dart';

final customThemeRepositoryProvider = Provider<CustomThemeRepository>(
  (ref) => CustomThemeRepositoryImpl(),
);

/// Repositório dos temas customizados, persistidos no box Hive
/// `custom_theme_packs` (aberto pelo app durante o setup).
class CustomThemeRepositoryImpl implements CustomThemeRepository {
  static const String _boxName = 'custom_theme_packs';

  Box<CustomThemePack>? get _box =>
      Hive.isBoxOpen(_boxName) ? Hive.box<CustomThemePack>(_boxName) : null;

  @override
  Future<List<CustomThemePack>> findAll() async {
    return _box?.values.toList(growable: false) ?? const <CustomThemePack>[];
  }

  @override
  Future<CustomThemePack?> findById(String uuid) async => _box?.get(uuid);

  @override
  Future<void> save(CustomThemePack pack) async {
    await _box?.put(pack.uuid, pack);
  }

  @override
  Future<void> delete(String uuid) async {
    await _box?.delete(uuid);
  }
}
