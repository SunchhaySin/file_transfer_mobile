import 'package:flutter/material.dart';

class UploadedFileTile extends StatelessWidget {
  final String uploadName;
  final String uploadExtension;
  final String uploadSize;
  final VoidCallback onTap;

  const UploadedFileTile({
    super.key,
    required this.uploadName,
    required this.uploadExtension,
    required this.uploadSize,
    required this.onTap,
  });

  // Return the matching Icon for each file/media type
  IconData _iconForExtension(String? extension) {
    switch (extension?.toLowerCase()) {
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
            Icon(_iconForExtension(uploadExtension), size: 28),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(uploadName, overflow: TextOverflow.ellipsis, maxLines: 1),
                  Text(
                    uploadSize,
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
