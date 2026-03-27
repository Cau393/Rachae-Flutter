import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:frontend/features/profile/models/ads_status_model.dart';
import 'package:frontend/features/profile/providers/ads_repository_provider.dart';
import 'package:frontend/src/l10n/generated/app_localizations.dart';

class ManageSubscriptionButton extends ConsumerWidget {
  const ManageSubscriptionButton({
    super.key,
    required this.model,
  });

  final AdsStatusModel model;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final expires = model.planExpiresAt;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (expires != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              l10n.profileAdFreeExpires(
                DateFormat.yMMMd().format(expires.toLocal()),
              ),
            ),
          ),
        OutlinedButton(
          onPressed: () async {
            final url =
                await ref.read(adsRepositoryProvider).createPortalSession();
            final uri = Uri.parse(url);
            if (context.mounted) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          },
          child: Text(l10n.profileManageSubscriptionButton),
        ),
      ],
    );
  }
}
