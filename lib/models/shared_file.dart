import 'dart:typed_data';
import 'package:path/path.dart' as p;

class SharedFile {
  final String name;
  final String path;
  final int size;
  final String mimeType;
  final Uint8List? bytes; // For web platform and Android content URIs
  final bool isContentUri; // Flag for Android content URIs

  SharedFile({
    required this.name,
    required this.path,
    required this.size,
    required this.mimeType,
    this.bytes,
    this.isContentUri = false,
  });

  String get fileName => p.basename(name);
  
  String get sizeFormatted {
    if (size < 1024) return '${size}B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)}KB';
    if (size < 1024 * 1024 * 1024) return '${(size / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }
}
