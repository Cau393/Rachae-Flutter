// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html' as html;
import 'dart:js_util' as js_util;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

/// AdSense auto unit in the same strip as the native banner (web only).
class WebAdsenseBanner extends StatefulWidget {
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
  State<WebAdsenseBanner> createState() => _WebAdsenseBannerState();
}

class _WebAdsenseBannerState extends State<WebAdsenseBanner> {
  late final String _viewType;

  @override
  void initState() {
    super.initState();
    final client = widget.client;
    final slot = widget.slot;
    final height = widget.height;

    _viewType =
        'adsense-${identityHashCode(this)}-${DateTime.now().microsecondsSinceEpoch}';

    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final container = html.DivElement()
        ..style.width = '100%'
        ..style.minHeight = '${height}px';

      final ins = html.Element.tag('ins')
        ..className = 'adsbygoogle'
        ..style.display = 'block'
        ..setAttribute('data-ad-client', client)
        ..setAttribute('data-ad-slot', slot)
        ..setAttribute('data-ad-format', 'auto')
        ..setAttribute('data-full-width-responsive', 'true');

      container.append(ins);
      unawaited(_pushWhenReady());
      return container;
    });
  }

  Future<void> _pushWhenReady() async {
    for (var i = 0; i < 100; i++) {
      if (!mounted) return;
      final ready = js_util.hasProperty(js_util.globalThis, 'adsbygoogle');
      if (ready) {
        try {
          js_util.callMethod<void>(js_util.globalThis, 'eval', <Object>[
            '(window.adsbygoogle = window.adsbygoogle || []).push({});',
          ]);
        } catch (_) {}
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: widget.height,
      child: HtmlElementView(viewType: _viewType),
    );
  }
}
