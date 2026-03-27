import 'package:flutter/material.dart';

/// Placeholder on VM/mobile test targets — real web UI is in
/// [web_sidebar_ad_web.dart].
class WebAdsenseBanner extends StatelessWidget {
  const WebAdsenseBanner({
    super.key,
    required this.client,
    required this.slot,
    this.height = 100,
  });

  final String client;
  final String slot;
  final double height;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
