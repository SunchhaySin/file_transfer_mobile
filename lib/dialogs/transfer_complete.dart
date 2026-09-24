import 'package:flutter/material.dart';

enum TransferCompleteChoice { save, discard }

class TransferCompleteDialog extends StatelessWidget {
  final String fileName;
  final int fileSize;

  const TransferCompleteDialog({
    super.key,
    required this.fileName,
    required this.fileSize,
  });

  static Future<TransferCompleteChoice?> show({
    required BuildContext context,
    required String fileName,
    required int fileSize,
  }) {
    return showDialog<TransferCompleteChoice>(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          TransferCompleteDialog(fileName: fileName, fileSize: fileSize),
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Transfer Complete',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
                ),
                SizedBox(width: 8,),
                Icon(Icons.check_circle_outline, color: Colors.green, size: 26,)
              ],
            ),
            Divider(color: Colors.black54, height: 18),
            SizedBox(height: 20,),

            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white70.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.black54.withOpacity(0.65)
                ),
              ),
              child: Row(children: [
                Container(
                  padding: EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [Colors.green.shade400, Colors.green.shade700],
                      ),
                    ),
                    child: Icon(Icons.abc_outlined),
                )
              ],)
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'File: $fileName',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Size: ${_formatSize(fileSize)}'),
              ],
            ),
            const SizedBox(height: 16),
            // const Row(
            //   children: [
            //     Icon(Icons.check_circle_outline, color: Colors.green),
            //     SizedBox(width: 8),
            //     Expanded(
            //       child: Text(
            //         'File received into RAM. Choose whether to save or discard it.',
            //       ),
            //     ),
            //   ],
            // ),
            Row(children: [

            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(TransferCompleteChoice.discard),
              child: const Text('Discard', style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.of(context).pop(TransferCompleteChoice.save),
              child: const Text('Save File'),
            ),
            ],)
          ],
        ),
      ),
    );
  }
}
