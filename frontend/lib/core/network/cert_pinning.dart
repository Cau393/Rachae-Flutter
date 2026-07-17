import 'package:dio/dio.dart';

import 'cert_pinning_stub.dart' if (dart.library.io) 'cert_pinning_io.dart'
    as impl;

/// Master switch for TLS certificate pinning against the Railway API host.
///
/// DISABLED by default. A wrong pin — or a pin that isn't rotated before the
/// pinned certificate expires — makes every API request fail with no
/// client-side recovery until an app update ships. Flip this only once:
///
/// 1. A verified, current pin has been captured (see
///    [pinnedRailwayCertSha256Hashes]) directly from the production host,
///    not guessed or copied from a staging/local cert.
/// 2. A *backup* pin for the next certificate is included alongside it —
///    Railway/Let's Encrypt certs rotate automatically (~90 days) with no
///    client-visible signal, so a single pin bricks the app on the next
///    rotation.
///
/// TODO(security): capture the production pin and enable. See
/// `.claude/plans/act-as-a-senior-smooth-sketch.md` finding M-4.
const bool kEnableCertPinning = false;

/// Host the pins below apply to. Only this host is pinned — Supabase, CDN,
/// and any other TLS connection use default platform validation untouched.
const String pinnedApiHost =
    'rachae-flutter-production-11b3.up.railway.app';

/// Base64 SHA-256 hashes of the **full leaf certificate DER** accepted when
/// [kEnableCertPinning] is true (whole-certificate pinning, not narrow SPKI
/// pinning — extracting just the SubjectPublicKeyInfo requires ASN.1 parsing
/// this app doesn't otherwise need a dependency for; `dart:io`'s
/// `X509Certificate` only exposes the full DER). Trade-off: this pin must be
/// refreshed on every cert renewal, even ones that reuse the same key,
/// whereas SPKI pinning would survive same-key renewals. Acceptable here
/// because the mechanism ships disabled — revisit if/when this is enabled.
///
/// Empty on purpose: no verified pin has been captured yet. To populate,
/// run against the **production** host right before enabling:
///
/// ```sh
/// openssl s_client -connect rachae-flutter-production-11b3.up.railway.app:443 \
///     -servername rachae-flutter-production-11b3.up.railway.app </dev/null 2>/dev/null \
///   | openssl x509 -outform der \
///   | openssl dgst -sha256 -binary | openssl base64
/// ```
const List<String> pinnedRailwayCertSha256Hashes = <String>[];

/// Wires certificate pinning into [dio]'s HTTP adapter when
/// [kEnableCertPinning] is true. No-op on web (browsers terminate TLS
/// themselves and expose no certificate-inspection hook to Dart) and a
/// no-op when disabled, so calling this unconditionally is always safe and
/// never changes behavior for any request other than to [pinnedApiHost].
void configureCertPinning(Dio dio) => impl.configureCertPinning(dio);
