/*
 * Copyright (c) 2024-2026. Patrick Schmidt.
 * All rights reserved.
 */

import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'ad_block_unit.dart';

/// Provider do banner de anúncio.
///
/// Stub local: nenhum anúncio é carregado — o provider resolve para `null`,
/// então os widgets consumidores simplesmente não exibem banner.
class _BannerAdFamily {
  FutureProvider<AdWithView?> call(AdSize adSize, AdBlockUnit unit) => _family((adSize, unit));

  static final _family = FutureProvider.family<AdWithView?, (AdSize, AdBlockUnit)>(
    (ref, key) async => null,
  );
}

final bannerAdProvider = _BannerAdFamily();

/// Se o formulário de consentimento (UMP) está disponível.
///
/// Stub local: sempre `false`, pois o SDK de anúncios não é inicializado.
final isConsentFormAvailableProvider = Provider<AsyncValue<bool>>(
  (ref) => const AsyncValue.data(false),
);
