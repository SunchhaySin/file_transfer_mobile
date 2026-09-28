import 'package:flutter/material.dart';
import 'package:file_transfer_mobile/helpers/iconGetter.dart';
import 'package:file_transfer_mobile/helpers/size_formatter.dart';

class TransferRequestDialog extends StatelessWidget {
  final List<dynamic> uploads;
  final int fileCount;
  final int fileSize;
  final String deviceId;
  final String deviceName;

  const TransferRequestDialog({
    super.key,
    required this.uploads,
    required this.fileCount,
    required this.fileSize,
    required this.deviceId,
    required this.deviceName,
  });


  final formatSize = const FormatFileSize();
  final iconHelper = const Icongetter();

  /// Static helper method to trigger the dialog directly
  static Future<bool> show({
    required BuildContext context,
    required List<dynamic> uploads,
    required int fileCount,
    required int fileSize,
    required String deviceName,
    required String deviceId,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => TransferRequestDialog(
        // fileName: fileName,
        uploads: uploads,
        fileCount: fileCount,
        fileSize: fileSize,
        deviceId: deviceId,
        deviceName: deviceName,
      ),
    );

    return result ?? false; // Default to false if dialog is dismissed
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Transfer Request',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
                ),
                SizedBox(width: 8),
                Icon(
                  Icons.install_mobile_outlined,
                  color: Colors.green.shade700,
                ),
              ],
            ),
            Divider(color: Colors.black54, height: 18),

            SizedBox(height: 6),
            Text(
              'Device "$deviceName" wants to send you $fileCount ${fileCount == 1 ? 'file' : 'files'}.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: 12),

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
                itemCount: fileCount,
                itemBuilder: (context, index) {
                  final file = uploads[index];
                  final fileName = file['fileName'];
                  final fileExt = file['extension'];
                  final fileSizeIndividual = file['fileSize'];

                  return Column(
                    children: [
                      if (index > 0) const Divider(height: 16, thickness: 1),

                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12.0),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  Colors.green.shade400,
                                  Colors.green.shade700,
                                ],
                              ),
                            ),
                            child: Icon(
                              iconHelper.getFileIcon(fileExt),
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(width: 12),

                          Expanded(
                            child: Column(
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
                                  formatSize.formatFileSize(fileSizeIndividual),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),

            SizedBox(height: 8),
            Text("Total Size: ${formatSize.formatFileSize(fileSize)}"),
            SizedBox(height: 8),

            // Action Buttons
            Row(
              children: [
                // Decline Button
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(10),
                      side: BorderSide(color: theme.colorScheme.error),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(
                      'Decline',
                      style: TextStyle(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Accept Button
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
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text(
                      'Accept',
                      style: TextStyle(fontWeight: FontWeight.bold),
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
