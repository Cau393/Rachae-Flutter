import 'dart:async';

import 'package:flutter/material.dart';

import 'package:frontend/features/ads/services/ad_service.dart';

class MockAdHandle implements AdHandle {
  MockAdHandle({this.onDispose});

  final void Function()? onDispose;

  @override
  bool isDisposed = false;

  @override
  final Widget adWidget = SizedBox(
    width: double.infinity,
    height: 50,
    child: Container(color: const Color(0xFFE0E0E0)),
  );

  @override
  void dispose() {
    if (isDisposed) return;
    isDisposed = true;
    onDispose?.call();
  }
}

/// Test/dev fake for widget and unit tests (no `google_mobile_ads`).
class MockAdService implements AdService {
  int initializeCallCount = 0;
  int loadBannerAdCallCount = 0;
  int disposeBannerAdCallCount = 0;

  String? lastAdUnitId;
  RachaeAdSize? lastSize;

  Completer<void>? loadCompleter;
  bool failNextLoad = false;
  String failCode = 'ERROR';
  String failMessage = 'mock failure';

  @override
  Future<void> initialize() async {
    initializeCallCount++;
  }

  @override
  Future<void> loadBannerAd({
    required String adUnitId,
    required RachaeAdSize size,
    required void Function(AdHandle handle) onLoaded,
    required void Function(String code, String message) onFailed,
  }) async {
    loadBannerAdCallCount++;
    lastAdUnitId = adUnitId;
    lastSize = size;

    if (loadCompleter != null) {
      await loadCompleter!.future;
    }

    if (failNextLoad) {
      onFailed(failCode, failMessage);
      return;
    }

    onLoaded(MockAdHandle());
  }

  @override
  Future<void> disposeBannerAd(AdHandle handle) async {
    disposeBannerAdCallCount++;
    handle.dispose();
  }
}
