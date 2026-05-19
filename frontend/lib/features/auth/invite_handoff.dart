import 'invite_handoff_stub.dart'
    if (dart.library.html) 'invite_handoff_web.dart'
    as impl;

/// Whether the web app is likely running in a mobile browser (phone/tablet).
bool isMobileInviteHandoffBrowser() => impl.isMobileInviteHandoffBrowser();

/// Attempts to open the installed iOS Rachae app with the invite token.
///
/// Web only. No-op on other platforms.
void tryOpenInstalledIosAppForInvite(String inviteToken) {
  impl.tryOpenInstalledIosAppForInvite(inviteToken);
}
