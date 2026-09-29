import 'package:file_transfer_mobile/helpers/size_formatter.dart';
import 'package:flutter/material.dart';
import 'package:file_transfer_mobile/helpers/iconGetter.dart';

class UploadedFileTile extends StatelessWidget {
  final String uploadName;
  final String uploadExtension;
  final int uploadSize;
  final VoidCallback onTap;

  const UploadedFileTile({
    super.key,
    required this.uploadName,
    required this.uploadExtension,
    required this.uploadSize,
    required this.onTap,
  });

  // Return the matching Icon for each file/media type
  final iconHelper = const Icongetter();
  final formatSize = const FormatFileSize();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        margin: EdgeInsets.all(2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white60
        ),
        child: Row(
          children: [
            Icon(iconHelper.getFileIcon(uploadExtension), size: 28),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(uploadName, overflow: TextOverflow.ellipsis, maxLines: 1),
                  Text(
                    formatSize.formatFileSize(uploadSize),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            SizedBox(width: 12),
            InkWell(
              onTap: onTap,
              child: Icon(Icons.delete_outline, color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}
