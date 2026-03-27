import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/features/ads/services/ad_service.dart';
import 'package:frontend/features/ads/services/admob_ad_service.dart';
import 'package:frontend/features/ads/services/no_op_ad_service.dart';

final adServiceProvider = Provider<AdService>(
  (ref) => kIsWeb ? NoOpAdService() : AdMobAdService(),
);
