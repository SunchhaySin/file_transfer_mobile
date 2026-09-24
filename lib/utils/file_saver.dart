import 'dart:io';
import 'dart:math' show min;
import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';

enum SaveResult { savedToGallery, savedToFiles, cancelled, failed }

class SafeFileSaver {
  SafeFileSaver._();

  static const Set<String> _galImageExtensions = {
    'jpg', 'jpeg', 'png', 'gif', 'webp', 'heic', 'heif', 'bmp',
  };

  static const Set<String> _galVideoExtensions = {
    'mp4', 'mov', 'm4v', '3gp',
  };

  /// Size of each write. Writing in chunks avoids making one giant native
  /// copy of the whole file and lets the UI render frames between chunks.
  static const int _chunkSize = 1024 * 1024; // 1 MB

  static Future<SaveResult> save({
    required BuildContext context,
    required String fileName,
    required Uint8List fileBytes,
    String? album,
  }) async {
    // Capture these BEFORE any await so we never touch `context` across
    // async gaps.
    final navigator = Navigator.of(context, rootNavigator: true);
    final messenger = ScaffoldMessenger.maybeOf(context);

    // ---- Parse file name (handles names with multiple dots) ----
    final safeName = _sanitizeFileName(fileName);
    final dotIndex = safeName.lastIndexOf('.');
    final ext = dotIndex > 0 && dotIndex < safeName.length - 1
        ? safeName.substring(dotIndex + 1).toLowerCase().trim()
        : '';
    final nameWithoutExt = dotIndex > 0 ? safeName.substring(0, dotIndex) : safeName;

    final isGalVideo = _galVideoExtensions.contains(ext);
    final isGalImage = _galImageExtensions.contains(ext);

    // ---- Spinner helpers ----
    var spinnerOpen = false;

    Future<void> showSpinner() async {
      if (!context.mounted) return;
      spinnerOpen = true;
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        useRootNavigator: true,
        builder: (_) => const PopScope(
          canPop: false,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
      // Give the dialog a moment to actually paint before heavy work starts.
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }

    void hideSpinner() {
      if (spinnerOpen) {
        spinnerOpen = false;
        navigator.pop();
      }
    }

    void toast(String message, {required bool isError}) {
      messenger?.showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : Colors.green,
        ),
      );
    }

    try {
      await showSpinner();

      // -----------------------------------------------------------
      // 1) Try the native gallery for images / videos
      // -----------------------------------------------------------
      if (isGalImage || isGalVideo) {
        final savedToGallery = await _saveToGallery(
          fileName: safeName,
          bytes: fileBytes,
          isVideo: isGalVideo,
          album: album,
        );

        if (savedToGallery) {
          hideSpinner();
          toast('Saved to Photos / Gallery!', isError: false);
          return SaveResult.savedToGallery;
        }
        // otherwise fall through to FileSaver
      }

      // -----------------------------------------------------------
      // 2) Fallback: FileSaver for documents / ZIPs or if Gal failed
      // -----------------------------------------------------------
      final String? path = await FileSaver.instance.saveFile(
        name: nameWithoutExt,
        bytes: fileBytes,
        fileExtension: ext,
      );

      hideSpinner();

      if (path != null) {
        toast('Saved $safeName to Files / Storage', isError: false);
        return SaveResult.savedToFiles;
      }
      return SaveResult.cancelled;
    } catch (e, st) {
      debugPrint('FileSaver error: $e\n$st');
      hideSpinner();
      toast('Failed to save file: $e', isError: true);
      return SaveResult.failed;
    } finally {
      // Safety net: never leave the spinner stuck on screen.
      hideSpinner();
    }
  }

  // ---------------------------------------------------------------
  // Gallery save (returns true on success, false if caller should fall back)
  // ---------------------------------------------------------------
  static Future<bool> _saveToGallery({
    required String fileName,
    required Uint8List bytes,
    required bool isVideo,
    String? album,
  }) async {
    Directory? tempSubDir;

    try {
      // Permission
      final needsAlbumAccess = album != null;
      var hasAccess = await Gal.hasAccess(toAlbum: needsAlbumAccess);
      if (!hasAccess) {
        hasAccess = await Gal.requestAccess(toAlbum: needsAlbumAccess);
      }
      if (!hasAccess) {
        debugPrint('Photo library permission denied, falling back.');
        return false;
      }

      // Unique temp folder so file names never collide and the gallery
      // still sees the original file name.
      final tempDir = await getTemporaryDirectory();
      tempSubDir = await Directory(
        '${tempDir.path}/gal_${DateTime.now().microsecondsSinceEpoch}',
      ).create(recursive: true);

      final tempFile = File('${tempSubDir.path}/$fileName');
      await _writeBytesChunked(tempFile, bytes);

      if (isVideo) {
        await Gal.putVideo(tempFile.path, album: album);
      } else {
        await Gal.putImage(tempFile.path, album: album);
      }
      return true;
    } on GalException catch (e) {
      debugPrint('Gal exception (${e.type}): falling back to FileSaver...');
      return false;
    } catch (e, st) {
      debugPrint('Gallery save error: $e\n$st\nFalling back to FileSaver...');
      return false;
    } finally {
      // Always clean up the temp folder, even on error.
      try {
        if (tempSubDir != null && await tempSubDir.exists()) {
          await tempSubDir.delete(recursive: true);
        }
      } catch (_) {}
    }
  }

  // ---------------------------------------------------------------
  // Chunked write: async, low memory overhead, UI stays responsive
  // ---------------------------------------------------------------
  static Future<void> _writeBytesChunked(File file, Uint8List bytes) async {
    final raf = await file.open(mode: FileMode.write);
    try {
      for (var offset = 0; offset < bytes.length; offset += _chunkSize) {
        final end = min(offset + _chunkSize, bytes.length);
        await raf.writeFrom(bytes, offset, end);
      }
      await raf.flush();
    } finally {
      await raf.close();
    }
  }

  // ---------------------------------------------------------------
  // Remove characters that are illegal in file names on some platforms
  // ---------------------------------------------------------------
  static String _sanitizeFileName(String name) {
    final cleaned = name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
    return cleaned.isEmpty ? 'file' : cleaned;
  }
}