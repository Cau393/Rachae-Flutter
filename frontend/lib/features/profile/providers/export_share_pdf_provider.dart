import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

/// Overridden in widget tests to avoid platform `sharePdf` channels.
final exportSharePdfProvider =
    Provider<Future<void> Function(Uint8List bytes)>((ref) {
  return (Uint8List bytes) => Printing.sharePdf(
        bytes: bytes,
        filename: 'rachae_export.pdf',
      );
});
