import 'package:flutter/material.dart';
import 'package:file_transfer_mobile/helpers/size_formatter.dart';
import 'package:file_transfer_mobile/utils/receive/data_reconstruction.dart';

enum TransferCompleteChoice { save, discard }

class TransferCompleteDialog extends StatelessWidget {
  final List<ReceivedFile> files;

  const TransferCompleteDialog({super.key, required this.files});

  final formatSize = const FormatFileSize();

  static Future<TransferCompleteChoice?> show({
    required BuildContext context,
    required List<ReceivedFile> files,
  }) {
    return showDialog<TransferCompleteChoice>(
      context: context,
      barrierDismissible: false,
      builder: (context) => TransferCompleteDialog(files: files),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                SizedBox(width: 8),
                Icon(Icons.check_circle, color: Colors.green, size: 30),
              ],
            ),
            Divider(color: Colors.black54, height: 18),
            SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(10),
              constraints: const BoxConstraints(maxHeight: 220),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(
                  0.5,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                ),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: files.length,
                itemBuilder: (context, index) {
                  final file = files[index];
                  final fileName = file.fileName;
                  final fileSizeBytes = file.fileBytes.length;

                  return Column(
                    children: [
                      if (index > 0) const Divider(height: 16, thickness: 1),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fileName,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            formatSize.formatFileSize(fileSizeBytes),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(10),
                      side: BorderSide(color: theme.colorScheme.outline),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.of(
                      context,
                    ).pop(TransferCompleteChoice.discard),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.delete_outline_sharp, color: Colors.red),
                        SizedBox(width: 6),
                        Text('Discard', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.all(10),
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () =>
                        Navigator.of(context).pop(TransferCompleteChoice.save),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.save_alt_rounded, color: Colors.black, size: 22),
                        SizedBox(width: 6),
                        Text('Save File', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
