// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:html' as html;

import 'package:frontend/features/auth/invite_deep_link.dart';

bool isMobileInviteHandoffBrowser() {
  final ua = html.window.navigator.userAgent.toLowerCase();
  if (ua.isEmpty) return false;
  // iPhone, iPad (incl. "Macintosh" iPadOS desktop mode), Android phones
  return ua.contains('iphone') ||
      ua.contains('ipad') ||
      ua.contains('android') ||
      (ua.contains('mobile') && !ua.contains('ipad'));
}

void tryOpenInstalledIosAppForInvite(String inviteToken) {
  final uri = buildIosFriendInviteAppUri(inviteToken);
  try {
    html.window.location.assign(uri.toString());
  } catch (_) {
    // Handoff is best-effort; user stays on web login.
  }
}
