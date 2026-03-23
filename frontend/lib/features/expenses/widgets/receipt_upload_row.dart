import 'dart:io';

import 'package:flutter/material.dart';

import 'package:frontend/src/l10n/generated/app_localizations.dart';

class ReceiptUploadRow extends StatelessWidget {
  const ReceiptUploadRow({
    super.key,
    required this.receiptQueue,
    required this.onAddReceipt,
    required this.onRemoveReceipt,
    this.addButtonLabel,
  });

  final List<File> receiptQueue;
  final VoidCallback onAddReceipt;
  final ValueChanged<File> onRemoveReceipt;
  final String? addButtonLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (final f in receiptQueue)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        f,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Material(
                      type: MaterialType.transparency,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 28,
                          minHeight: 28,
                        ),
                        style: IconButton.styleFrom(
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        icon: const Icon(Icons.close, size: 12),
                        onPressed: () => onRemoveReceipt(f),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          TextButton.icon(
            onPressed: onAddReceipt,
            icon: const Icon(Icons.add_a_photo),
            label: Text(addButtonLabel ?? l10n.addExpenseReceiptLabel),
          ),
        ],
      ),
    );
  }
}
