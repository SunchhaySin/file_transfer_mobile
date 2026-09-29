import 'package:flutter/material.dart';

class Icongetter {
  const Icongetter(); 

  IconData getFileIcon(String ext) {
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
}