/*
 * Copyright (c) 2024-2026. Patrick Schmidt.
 * All rights reserved.
 */

import 'package:common/ui/theme/theme_pack.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/model/custom_theme_pack.dart';
import '../repository/custom_theme_repository.dart';
import '../repository/custom_theme_repository_impl.dart';

final customThemeServiceProvider = Provider<CustomThemeService>(
  (ref) => CustomThemeService(ref),
);

/// Todos os temas customizados salvos (AsyncValue com `.when`/`.value`).
final customThemePacksProvider = FutureProvider<List<CustomThemePack>>(
  (ref) => ref.watch(customThemeRepositoryProvider).findAll(),
);

/// Temas customizados já convertidos em [ThemePack] (síncrono — usado dentro
/// do override de `themePackProvider` no `theme_setup.dart`).
final customThemePacksAsThemePackProvider = Provider<List<ThemePack>>((ref) {
  final packs = ref.watch(customThemePacksProvider).value ?? const <CustomThemePack>[];
  return [for (final pack in packs) buildThemePack(pack)];
});

class CustomThemeService {
  CustomThemeService(this._ref);

  final Ref _ref;

  CustomThemeRepository get _repository => _ref.read(customThemeRepositoryProvider);

  Future<void> save(CustomThemePack pack) async {
    final effective = pack.uuid.isEmpty ? pack.copyWith(uuid: const Uuid().v4()) : pack;
    await _repository.save(effective);
    _ref.invalidate(customThemePacksProvider);
  }

  Future<void> delete(CustomThemePack pack) async {
    await _repository.delete(pack.uuid);
    _ref.invalidate(customThemePacksProvider);
  }
}
