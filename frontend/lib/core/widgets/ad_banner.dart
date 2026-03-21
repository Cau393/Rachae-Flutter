import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdStatus {
  const AdStatus({required this.isAdFree});

  final bool isAdFree;
}

final adStatusProvider = Provider<AdStatus>(
  (ref) => const AdStatus(isAdFree: false),
);

class AdBanner extends ConsumerWidget {
  const AdBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(adStatusProvider);
    if (status.isAdFree) {
      return const SizedBox.shrink();
    }
    // TODO: replace with AdMob BannerAd in Phase 23
    return SizedBox(
      width: double.infinity,
      child: Container(
        height: 50,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Center(
          child: Text(
            'Ad',
            style: TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ),
      ),
    );
  }
}
