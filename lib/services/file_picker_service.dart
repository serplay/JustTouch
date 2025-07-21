import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:mime/mime.dart';
import 'package:logging/logging.dart';
import '../models/shared_file.dart';

class FilePickerService {
  static final Logger _logger = Logger('FilePickerService');

  static Future<List<SharedFile>> pickFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
        withData: kIsWeb, // Load bytes for web, skip for mobile/desktop
        withReadStream: false,
      );

      if (result != null && result.files.isNotEmpty) {
        List<SharedFile> sharedFiles = [];

        for (final file in result.files) {
          // Handle web vs native platforms differently
          if (kIsWeb) {
            // Web: use bytes and file name
            if (file.bytes != null) {
              final mimeType =
                  lookupMimeType(file.name) ?? 'application/octet-stream';

              sharedFiles.add(
                SharedFile(
                  name: file.name,
                  path: file.name, // Use name as path for web
                  size: file.bytes!.length,
                  mimeType: mimeType,
                  bytes: file.bytes, // Store bytes for web
                ),
              );
            }
          } else {
            // Native: use file path
            if (file.path != null) {
              final fileObj = File(file.path!);
              final fileStats = await fileObj.stat();
              final mimeType =
                  lookupMimeType(file.path!) ?? 'application/octet-stream';

              sharedFiles.add(
                SharedFile(
                  name: file.name,
                  path: file.path!,
                  size: fileStats.size,
                  mimeType: mimeType,
                ),
              );
            }
          }
        }

        return sharedFiles;
      }

      return [];
    } catch (e) {
      _logger.severe('Error picking files: $e');
      return [];
    }
  }

  static Future<SharedFile?> pickSingleFile() async {
    final files = await pickFiles();
    return files.isNotEmpty ? files.first : null;
  }
}
