import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:frontend/src/config/legal_config.dart';
import 'package:frontend/src/l10n/generated/app_localizations.dart';

/// Terms of Use (EULA) + Privacy Policy links, shown on the Profile screen so
/// they are reachable outside of the paywall too.
///
/// See `docs/app-review-rejection-plan-2026-07-07.md` Issue 3 (Guideline
/// 3.1.2(c)) — subscription apps must have a functional EULA link reachable
/// in-app.
class LegalLinksSection extends StatelessWidget {
  const LegalLinksSection({super.key});

  Future<void> _open(BuildContext context, String url) async {
    final l10n = AppLocalizations.of(context)!;
    final uri = Uri.parse(url);
    final canLaunch = await canLaunchUrl(uri);
    if (!context.mounted) return;
    if (!canLaunch) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text(l10n.profileCheckoutCannotOpenUrl)),
      );
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          leading: const Icon(Icons.description_outlined),
          title: Text(l10n.profileTermsOfUseButton),
          onTap: () => _open(context, LegalConfig.eulaUrl),
        ),
        ListTile(
          leading: const Icon(Icons.privacy_tip_outlined),
          title: Text(l10n.profilePrivacyPolicyButton),
          onTap: () => _open(context, LegalConfig.privacyPolicyUrl),
        ),
      ],
    );
  }
}
