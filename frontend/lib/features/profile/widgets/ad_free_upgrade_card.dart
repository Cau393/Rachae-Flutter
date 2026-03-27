import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:frontend/features/profile/providers/ads_repository_provider.dart';
import 'package:frontend/src/l10n/generated/app_localizations.dart';

class AdFreeUpgradeCard extends ConsumerStatefulWidget {
  const AdFreeUpgradeCard({super.key});

  @override
  ConsumerState<AdFreeUpgradeCard> createState() => _AdFreeUpgradeCardState();
}

class _AdFreeUpgradeCardState extends ConsumerState<AdFreeUpgradeCard> {
  String _plan = 'monthly';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: Text(l10n.adFreeMonthlyPlan),
                  selected: _plan == 'monthly',
                  onSelected: (_) => setState(() => _plan = 'monthly'),
                ),
                ChoiceChip(
                  label: Text(l10n.adFreeYearlyPlan),
                  selected: _plan == 'yearly',
                  onSelected: (_) => setState(() => _plan = 'yearly'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () async {
                final url = await ref
                    .read(adsRepositoryProvider)
                    .createCheckoutSession(plan: _plan);
                final uri = Uri.parse(url);
                if (context.mounted) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              child: Text(l10n.profileUpgradeButton),
            ),
          ],
        ),
      ),
    );
  }
}
