import 'package:flutter/material.dart';

class TransferProgressDialog extends StatefulWidget {
  final String fileName;
  final int fileSize;

  const TransferProgressDialog({
    super.key,
    required this.fileName,
    required this.fileSize,
  });

  static Future<void> show({
    required BuildContext context,
    required String fileName,
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
          fileName: fileName,
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
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Receiving File...'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('File: ${widget.fileName}', style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Size: ${_formatSize(widget.fileSize)}'),
          const SizedBox(height: 16),
          LinearProgressIndicator(value: _progress),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text('${(_progress * 100).toStringAsFixed(1)}%'),
          ),
        ],
      ),
    );
  }
}

class TransferProgressController {
  final GlobalKey<_TransferProgressDialogState> _key = GlobalKey<_TransferProgressDialogState>();
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