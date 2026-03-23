// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:html' as html;

String webApiBaseUrl() {
  final loc = html.window.location;
  final scheme = loc.protocol.replaceFirst(':', '');
  final host = loc.hostname ?? '';
  if (host.isEmpty) {
    return '';
  }
  return '$scheme://$host:8000/api/v1/';
}
