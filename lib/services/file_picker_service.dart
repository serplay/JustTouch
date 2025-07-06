import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:mime/mime.dart';
import '../models/shared_file.dart';

class FilePickerService {
  static Future<List<SharedFile>> pickFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
        withData: false,
        withReadStream: false,
      );

      if (result != null && result.files.isNotEmpty) {
        List<SharedFile> sharedFiles = [];
        
        for (final file in result.files) {
          if (file.path != null) {
            final fileObj = File(file.path!);
            final fileStats = await fileObj.stat();
            final mimeType = lookupMimeType(file.path!) ?? 'application/octet-stream';
            
            sharedFiles.add(SharedFile(
              name: file.name,
              path: file.path!,
              size: fileStats.size,
              mimeType: mimeType,
            ));
          }
        }
        
        return sharedFiles;
      }
      
      return [];
    } catch (e) {
      print('Error picking files: $e');
      return [];
    }
  }
  
  static Future<SharedFile?> pickSingleFile() async {
    final files = await pickFiles();
    return files.isNotEmpty ? files.first : null;
  }
}
