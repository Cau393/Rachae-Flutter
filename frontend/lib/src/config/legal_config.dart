/// Public legal document URLs, used wherever the app must link to them
/// (Profile/Settings screen, App Store metadata).
///
/// Keeping these in one place avoids duplicated literals drifting apart —
/// see `docs/app-review-rejection-plan-2026-07-07.md` Issue 3.
class LegalConfig {
  LegalConfig._();

  /// Apple's standard EULA, used as this app's Terms of Use.
  static const eulaUrl =
      'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/';

  /// Hosted Privacy Policy.
  static const privacyPolicyUrl =
      'https://web-beige-zeta-71.vercel.app/privacy.html';
}
