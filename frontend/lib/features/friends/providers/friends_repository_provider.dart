import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/core/providers/core_providers.dart';
import 'package:frontend/features/friends/repositories/friends_repository.dart';

final friendsRepositoryProvider = Provider<FriendsRepository>((ref) {
  return FriendsRepository(ref.watch(dioProvider));
});
