import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/core/router/app_router.dart';
import 'package:frontend/features/auth/invite_deep_link.dart';
import 'package:frontend/features/auth/ios_oauth_safari_dismiss.dart';

/// iOS: handles warm-start app link callbacks (OAuth dismiss + friend invite).
class IosAppLinkListener extends ConsumerStatefulWidget {
  const IosAppLinkListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<IosAppLinkListener> createState() => _IosAppLinkListenerState();
}

class _IosAppLinkListenerState extends ConsumerState<IosAppLinkListener> {
  StreamSubscription<Uri>? _sub;

  @override
  void initState() {
    super.initState();
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return;
    _sub = AppLinks().uriLinkStream.listen(_onUri, onError: (_, _) {});
  }

  void _onUri(Uri uri) {
    unawaited(maybeDismissInAppWebViewForIosOAuth(uri));
    final token = parseInviteTokenFromIosCustomSchemeUri(uri);
    if (token == null || token.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(appRouterProvider)
          .go('/login?invite_token=${Uri.encodeQueryComponent(token)}');
    });
  }

  @override
  void dispose() {
    unawaited(_sub?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
