/*
 * Copyright (c) 2024-2026. Patrick Schmidt.
 * All rights reserved.
 */

import '../data/model/custom_theme_pack.dart';

/// Contrato do repositório dos temas customizados.
abstract class CustomThemeRepository {
  Future<List<CustomThemePack>> findAll();

  Future<CustomThemePack?> findById(String uuid);

  Future<void> save(CustomThemePack pack);

  Future<void> delete(String uuid);
}
