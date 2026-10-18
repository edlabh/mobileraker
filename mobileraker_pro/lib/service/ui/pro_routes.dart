/*
 * Copyright (c) 2024-2026. Patrick Schmidt.
 * All rights reserved.
 */

import 'package:common/service/app_router.dart';

/// Rotas pertencentes ao pacote PRO.
///
/// O valor de `.name` é usado como `GoRoute.name` no roteador do app.
enum ProRoutes implements RouteDefinitionMixin {
  fileManager_exlorer_gcodePreview,
  spoolman,
  spoolman_details_spool,
  spoolman_details_filament,
  spoolman_details_vendor,
  spoolman_form_spool,
  spoolman_form_filament,
  spoolman_form_vendor,
}
