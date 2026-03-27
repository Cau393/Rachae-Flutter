import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/core/providers/core_providers.dart';
import 'package:frontend/features/profile/repositories/profile_repository.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(dioProvider));
});
