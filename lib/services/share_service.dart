import 'package:flutter/services.dart';
import 'dart:typed_data';
import '../models/shared_file.dart';

class ShareService {
  static const MethodChannel _channel = MethodChannel('com.example.jtv7/share');
  static Function(List<SharedFile>)? _onFilesSharedCallback;

  static void initialize() {
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  static void setOnFilesSharedCallback(Function(List<SharedFile>) callback) {
    _onFilesSharedCallback = callback;
  }

  static Future<void> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onFileShared':
        final List<dynamic> fileData = call.arguments;
        final SharedFile sharedFile = _parseSharedFile(fileData[0]);
        _onFilesSharedCallback?.call([sharedFile]);
        break;
      case 'onFilesShared':
        final List<dynamic> filesData = call.arguments;
        final List<SharedFile> sharedFiles = filesData
            .map((fileData) => _parseSharedFile(fileData))
            .toList();
        _onFilesSharedCallback?.call(sharedFiles);
        break;
    }
  }

  static SharedFile _parseSharedFile(Map<dynamic, dynamic> fileData) {
    // Handle bytes from Android content URIs
    Uint8List? bytes;
    if (fileData['bytes'] != null) {
      final bytesData = fileData['bytes'];
      if (bytesData is List<int>) {
        bytes = Uint8List.fromList(bytesData);
      }
    }
    
    return SharedFile(
      path: fileData['path'] as String,
      name: fileData['name'] as String,
      size: (fileData['size'] as num).toInt(),
      mimeType: fileData['mimeType'] as String? ?? 'application/octet-stream',
      bytes: bytes,
      isContentUri: fileData['isContentUri'] as bool? ?? false,
    );
  }
}
