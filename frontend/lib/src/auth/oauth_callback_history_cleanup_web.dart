// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:html' as html;

import 'oauth_callback_sanitizer.dart';

void cleanupOAuthCallbackHistory() {
  final current = Uri.base;
  if (!shouldSanitizeOAuthCallbackUri(current)) {
    return;
  }
  final sanitized = sanitizeOAuthCallbackUri(current);
  html.window.history.replaceState(null, '', sanitized.toString());
}
