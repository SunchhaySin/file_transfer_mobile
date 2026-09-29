import 'package:flutter/material.dart';
import 'dart:async';

class TransferProgressDialog extends StatefulWidget {
  final List<dynamic> uploads;
  final int fileSize;

  const TransferProgressDialog({
    super.key,
    required this.uploads,
    required this.fileSize,
  });

  static Future<void> show({
    required BuildContext context,
    required List<dynamic> uploads,
    required int fileSize,
    required Function(TransferProgressController controller) onReady,
  }) {
    final controller = TransferProgressController();

    return showDialog<void>(
      context: context,
      barrierDismissible: false, // Prevent dismissing mid-transfer
      builder: (dialogContext) {
        controller._context = dialogContext;
        onReady(controller);
        return TransferProgressDialog(
          uploads: uploads,
          fileSize: fileSize,
          key: controller._key,
        );
      },
    );
  }

  @override
  State<TransferProgressDialog> createState() => _TransferProgressDialogState();
}

class _TransferProgressDialogState extends State<TransferProgressDialog> {
  double _progress = 0.0;

  void updateProgress(double progress) {
    if (!mounted) return;
    setState(() {
      _progress = progress;
    });
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    // final bool isComplete = _progress >= 1.0;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      // title: const Text('Transfer Progess...'),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Transfer Progess',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
            ),
            Divider(color: Colors.black54, height: 18),

            Text('Size: ${_formatSize(widget.fileSize)}'),
            const SizedBox(height: 16),
            SizedBox(
              height: 6,
              child: LinearProgressIndicator(
                value: _progress,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text('${(_progress * 100).toStringAsFixed(1)}%'),
            ),
          ],
        ),
      ),
    );
  }
}

class TransferProgressController {
  final GlobalKey<_TransferProgressDialogState> _key =
      GlobalKey<_TransferProgressDialogState>();
  BuildContext? _context;

  void updateProgress(double progress) {
    _key.currentState?.updateProgress(progress);
  }

  void close() {
    if (_context != null && Navigator.canPop(_context!)) {
      Navigator.of(_context!).pop();
    }
  }
}