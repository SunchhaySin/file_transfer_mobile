import 'package:flutter/material.dart';

class TransferRequestDialog extends StatelessWidget {
  final String fileName;
  final int fileSize;
  final String deviceId;
  final String deviceName;

  const TransferRequestDialog({
    super.key,
    required this.fileName,
    required this.fileSize,
    required this.deviceId,
    required this.deviceName,
  });

  /// Helper to convert bytes to human-readable size
  String _formatFileSize(int bytes) {
    if (bytes <= 0) return "0 B";
    if (bytes < 1024) return "$bytes B";
    if (bytes < 1024 * 1024) return "${(bytes / 1024).toStringAsFixed(1)} KB";
    if (bytes < 1024 * 1024 * 1024) {
      return "${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB";
    }
    return "${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB";
  }

  IconData _getFileIcon(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'heic':
        return Icons.image_outlined;
      case 'mov':
      case 'mp4':
        return Icons.videocam_outlined;
      case 'pdf':
        return Icons.picture_as_pdf_outlined;
      case 'zip':
        return Icons.folder_zip_outlined;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }

  /// Static helper method to trigger the dialog directly
  static Future<bool> show({
    required BuildContext context,
    required String fileName,
    required int fileSize,
    required String deviceName,
    required String deviceId,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false, 
      builder: (context) => TransferRequestDialog(
        fileName: fileName,
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
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
                  style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                          ),
                ),
                SizedBox(width: 8,),
                Icon(Icons.install_mobile_outlined, color: Colors.green.shade700)
              ],
            ),
            Divider(color: Colors.black54, height: 18),
            
            SizedBox(height: 6,),
            Text(
              'Device "$deviceName" wants to send you a file.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [Colors.green.shade400, Colors.green.shade700],
                      ),
                    ),
                    child: Icon(
                      _getFileIcon(fileName),
                      color: Colors.black
                    ),
                  ),
                  SizedBox(width: 12),
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
                        SizedBox(height: 2),
                        Text(
                          _formatFileSize(fileSize),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black54
                          )
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
           SizedBox(height: 15),

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
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
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