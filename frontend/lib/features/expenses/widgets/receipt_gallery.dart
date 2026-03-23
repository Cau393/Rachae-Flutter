import 'package:flutter/material.dart';

import 'package:frontend/src/l10n/generated/app_localizations.dart';

class ReceiptGallery extends StatelessWidget {
  const ReceiptGallery({super.key, required this.receiptUrls});

  final List<String> receiptUrls;

  void _openFullscreen(BuildContext context, String url) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 4,
            child: Image.network(url, fit: BoxFit.contain),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (receiptUrls.isEmpty) {
      return Text(l10n.expenseDetailNoReceipts);
    }

    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: receiptUrls.length,
        itemBuilder: (context, i) {
          final url = receiptUrls[i];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => _openFullscreen(context, url),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  url,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
