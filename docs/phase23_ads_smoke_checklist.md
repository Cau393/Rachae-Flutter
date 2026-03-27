# Phase 23 — Ads integration smoke checklist

Use this document for **Step 6** manual QA after automated tests pass. It mirrors `.cursor/plans/23_add_real_ads.md` (integration checklist).

## 1. Automated pre-gate (required before manual pass)

From the `frontend/` directory:

```bash
flutter test test/features/ads/ test/core/widgets/ad_banner_test.dart test/integration/phase22_step8_smoke_test.dart
```

Placement and `isAdFree` behavior are also asserted in `test/features/ads/ad_placement_guard_test.dart` (inside `test/features/ads/`).

## 2. Simulator / device — banners and placement

Build with **test** AdMob IDs (debug builds use test banner units in `lib/features/ads/constants/ad_unit_ids.dart`). iOS app ID: `ios/Runner/Info.plist` key `GADApplicationIdentifier` (currently Google sample test ID).

- [ ] **Dashboard** — Test banner (or grey “Test Ad” placeholder flow) at **bottom**, **outside** the scrolling activity area.
- [ ] **Group list** — Test banner at bottom of screen body.
- [ ] **Friends** — Test banner at bottom of screen body.
- [ ] **Group detail — Expenses tab only** — Banner visible on **Expenses**; switch to **Balances** and **Members** — **no** bottom banner.
- [ ] **Expense detail** — No ad and no grey 50px placeholder strip.
- [ ] **Add expense** — No ad.
- [ ] **Settle up** — No ad.
- [ ] **Profile** — No ad.
- [ ] **Login / splash** — No ad.

### Ad-free in debug (`isAdFree`)

- [ ] Force `GET /ads/status/` (or a temporary `adsStatusProvider` override in debug) to return **`isAdFree: true`** — all visible ad slots should go away (dashboard omits `AdBanner` when not needed; other allowed screens mount `AdBanner` which collapses to zero height when ad-free — confirm visually).

### Physical devices

- [ ] **iOS** — Install on device; confirm banner loads with test App ID and network.
- [ ] **Android** — See [§4 Android](#4-android-application_id-when-android-module-exists). Repeat the same visual checks after the manifest is configured.

## 3. Staging — Stripe subscription and cold start

Requires deployed backend, Stripe webhooks, and a test user.

- [ ] Subscribe via Stripe Checkout → webhook updates user → **restart app** → **no** ads (`isAdFree`).
- [ ] Cancel subscription → webhook → **restart app** → ads **return**.
- [ ] After subscribing, **force-kill** app and relaunch → still ad-free (`adsStatusProvider` / `GET /ads/status/` refetch).

## 4. Android `APPLICATION_ID` (when `android/` module exists)

This repo may not include `frontend/android/` yet. When the Android app target is added, inside **`android/app/src/main/AndroidManifest.xml`**, under `<application>`, add AdMob **application** id (not the banner unit id):

**Google test App ID (sample):**

```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-3940256099942544~3347511713"/>
```

Replace with your production App ID before release. Banner unit IDs stay in Dart (`AdUnitIds`).

After adding, run §2 checks on an Android device or emulator.

## 5. Web — AdSense

On `kIsWeb`, `AdBanner` does **not** use the Mobile Ads SDK. It mounts an AdSense **auto** unit via `HtmlElementView` (`WebAdsenseBanner`), with a reserved height of `AppConfig.adSenseBannerHeight` (see `lib/src/config/app_config.dart`).

- [ ] **`web/index.html`** — The `adsbygoogle.js?client=…` query **must match** `AppConfig.adSenseClient` / `--dart-define=AD_SENSE_CLIENT` for production builds. Slot id uses `AD_SENSE_SLOT` (defaults documented in `AppConfig`).
- [ ] **`ads.txt`** — Publish on the **same host** as the web app (AdSense requirement).
- [ ] Spot-check allowed screens (dashboard, groups, friends, group detail expenses tab): strip does not block scroll on narrow viewports.

## 6. iOS — ATT before Mobile Ads

- [ ] **Info.plist** — `NSUserTrackingUsageDescription` is set (user-facing sentence for the ATT dialog).
- [ ] **Cold start** — System ATT prompt appears **before** `MobileAds.instance.initialize()` (see `lib/main.dart` → `_initializeNativeMobileAds`).
- [ ] **Denied / restricted** — Banners still load with **non-personalized** `AdRequest` (`AdTargetingConfig` + `admob_ad_service.dart`).
