import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import '../models/shared_file.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:network_info_plus/network_info_plus.dart';
import 'package:flutter/foundation.dart';

class FileServerService {
  HttpServer? _server;
  List<SharedFile> _files = [];
  static const int port = 8080;
  String? _serverUrl;

  bool get isRunning => _server != null;
  List<SharedFile> get files => _files;
  String? get serverUrl => _serverUrl;

  Future<String?> startServer(List<SharedFile> files) async {
    if (_server != null) {
      await stopServer();
    }

    _files = files;

    try {
      String? deviceIp;
      if (kIsWeb) {
        throw Exception('File server is not supported on web');
      }
      if (Platform.isIOS) {
        // iOS: użyj network_info_plus
        final info = NetworkInfo();
        deviceIp = await info.getWifiIP();
        if (deviceIp == null || deviceIp == '127.0.0.1') {
          throw Exception('Could not find device IP address. Make sure you are connected to WiFi.');
        }
      } else if (Platform.isMacOS) {
        // macOS: znajdź prawdziwy adres IP sieci lokalnej
        final interfaces = await NetworkInterface.list();
        for (final interface in interfaces) {
          for (final addr in interface.addresses) {
            if (addr.type == InternetAddressType.IPv4 && 
                !addr.isLoopback && 
                !addr.address.startsWith('169.254') &&
                !addr.address.startsWith('127.')) {
              deviceIp = addr.address;
              break;
            }
          }
          if (deviceIp != null) break;
        }
        if (deviceIp == null) {
          throw Exception('Could not find device IP address on macOS. Make sure you are connected to a network.');
        }
      } else {
        // Android, Windows, Linux: stara metoda
        final interfaces = await NetworkInterface.list();
        for (final interface in interfaces) {
          for (final addr in interface.addresses) {
            if (addr.type == InternetAddressType.IPv4 && 
                !addr.isLoopback && 
                !addr.address.startsWith('169.254')) {
              deviceIp = addr.address;
              break;
            }
          }
          if (deviceIp != null) break;
        }
        if (deviceIp == null) {
          throw Exception('Could not find device IP address.');
        }
      }

      final router = Router();

      // Home page with file listing
      router.get('/', _handleHomePage);
      
      // Download individual files
      router.get('/download/<fileIndex>', _handleFileDownload);
      
      // Download all files as ZIP (future enhancement)
      router.get('/download-all', _handleDownloadAll);

      final handler = Pipeline()
          .addMiddleware(logRequests())
          .addHandler(router.call);

      _server = await io.serve(
        handler,
        InternetAddress.anyIPv4,
        port,
      );

      final serverUrl = 'http://$deviceIp:$port';
      _serverUrl = serverUrl;
      print('File server started at $serverUrl');
      return serverUrl;
    } catch (e) {
      print('Error starting server: $e');
      return null;
    }
  }

  Future<void> stopServer() async {
    if (_server != null) {
      await _server!.close();
      _server = null;
      _files.clear();
      _serverUrl = null;
      print('File server stopped');
    }
  }

  Response _handleHomePage(Request request) {
    final html = _generateHomePage();
    return Response.ok(
      html,
      headers: {'Content-Type': 'text/html; charset=utf-8'},
    );
  }

  Future<Response> _handleFileDownload(Request request) async {
    final fileIndexStr = request.params['fileIndex'];
    if (fileIndexStr == null) {
      return Response.notFound('File not found');
    }

    final fileIndex = int.tryParse(fileIndexStr);
    if (fileIndex == null || fileIndex < 0 || fileIndex >= _files.length) {
      return Response.notFound('File not found');
    }

    final file = _files[fileIndex];
    try {
      // Check if we have bytes (from web or Android content URIs)
      if (file.bytes != null) {
        // Use stored bytes (web platform or Android content URIs)
        final mimeType = lookupMimeType(file.fileName) ?? 'application/octet-stream';
        
        return Response.ok(
          file.bytes!,
          headers: {
            'Content-Type': mimeType,
            'Content-Disposition': 'attachment; filename="${file.fileName}"',
            'Content-Length': '${file.bytes!.length}',
          },
        );
      } else if (kIsWeb) {
        return Response.internalServerError(body: 'File bytes not available on web');
      } else {
        // Native: read from file path (regular files, not content URIs)
        final fileData = await File(file.path).readAsBytes();
        final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';
        
        return Response.ok(
          fileData,
          headers: {
            'Content-Type': mimeType,
            'Content-Disposition': 'attachment; filename="${file.fileName}"',
            'Content-Length': '${fileData.length}',
          },
        );

      }
    } catch (e) {
      return Response.internalServerError(body: 'Error reading file: $e');
    }
  }

  Response _handleDownloadAll(Request request) {
    // Future enhancement: Create ZIP archive of all files
    return Response.ok('Download all feature coming soon!');
  }

  String _generateHomePage() {
    final buffer = StringBuffer();
    buffer.writeln('<!DOCTYPE html>');
    buffer.writeln('<html lang="en">');
    buffer.writeln('<head>');
    buffer.writeln('    <meta charset="UTF-8">');
    buffer.writeln('    <meta name="viewport" content="width=device-width, initial-scale=1.0">');
    buffer.writeln('    <title>JustTouch - File Share</title>');
    buffer.writeln('    <style>');
    buffer.writeln('        body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; margin: 0; padding: 20px; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); min-height: 100vh; }');
    buffer.writeln('        .container { max-width: 800px; margin: 0 auto; background: white; border-radius: 16px; box-shadow: 0 20px 40px rgba(0,0,0,0.1); overflow: hidden; }');
    buffer.writeln('        .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; text-align: center; }');
    buffer.writeln('        .header h1 { margin: 0; font-size: 2.5em; font-weight: 300; }');
    buffer.writeln('        .header p { margin: 10px 0 0 0; opacity: 0.9; font-size: 1.1em; }');
    buffer.writeln('        .content { padding: 30px; }');
    buffer.writeln('        .file-list { list-style: none; padding: 0; margin: 0; }');
    buffer.writeln('        .file-item { display: flex; align-items: center; justify-content: space-between; padding: 15px; margin: 10px 0; background: #f8f9fa; border-radius: 12px; transition: all 0.3s ease; }');
    buffer.writeln('        .file-item:hover { background: #e9ecef; transform: translateY(-2px); box-shadow: 0 5px 15px rgba(0,0,0,0.1); }');
    buffer.writeln('        .file-info { display: flex; align-items: center; flex: 1; }');
    buffer.writeln('        .file-icon { width: 40px; height: 40px; background: #667eea; border-radius: 8px; display: flex; align-items: center; justify-content: center; margin-right: 15px; color: white; font-weight: bold; }');
    buffer.writeln('        .file-details h3 { margin: 0; font-size: 1.1em; color: #333; }');
    buffer.writeln('        .file-details p { margin: 5px 0 0 0; color: #666; font-size: 0.9em; }');
    buffer.writeln('        .download-btn { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; border: none; padding: 10px 20px; border-radius: 8px; cursor: pointer; font-weight: 500; text-decoration: none; transition: all 0.3s ease; }');
    buffer.writeln('        .download-btn:hover { transform: translateY(-1px); box-shadow: 0 5px 15px rgba(102, 126, 234, 0.3); }');
    buffer.writeln('        .empty-state { text-align: center; padding: 60px 20px; color: #666; }');
    buffer.writeln('        .empty-state h2 { color: #333; margin-bottom: 10px; }');
    buffer.writeln('        @media (max-width: 600px) { .file-item { flex-direction: column; text-align: center; } .file-info { flex-direction: column; margin-bottom: 15px; } .file-icon { margin-right: 0; margin-bottom: 10px; } }');
    buffer.writeln('    </style>');
    buffer.writeln('</head>');
    buffer.writeln('<body>');
    buffer.writeln('    <div class="container">');
    buffer.writeln('        <div class="header">');
    buffer.writeln('            <h1>📁 JustTouch</h1>');
    buffer.writeln('            <p>Touch-to-share file transfer</p>');
    buffer.writeln('        </div>');
    buffer.writeln('        <div class="content">');

    if (_files.isEmpty) {
      buffer.writeln('            <div class="empty-state">');
      buffer.writeln('                <h2>No files shared</h2>');
      buffer.writeln('                <p>The sender hasn\'t selected any files to share yet.</p>');
      buffer.writeln('            </div>');
    } else {
      buffer.writeln('            <ul class="file-list">');
      for (int i = 0; i < _files.length; i++) {
        final file = _files[i];
        final extension = p.extension(file.fileName).toLowerCase();
        final icon = _getFileIcon(extension);
        
        buffer.writeln('                <li class="file-item">');
        buffer.writeln('                    <div class="file-info">');
        buffer.writeln('                        <div class="file-icon">$icon</div>');
        buffer.writeln('                        <div class="file-details">');
        buffer.writeln('                            <h3>${_escapeHtml(file.fileName)}</h3>');
        buffer.writeln('                            <p>${file.sizeFormatted} • ${file.mimeType}</p>');
        buffer.writeln('                        </div>');
        buffer.writeln('                    </div>');
        buffer.writeln('                    <a href="/download/$i" class="download-btn">Download</a>');
        buffer.writeln('                </li>');
      }
      buffer.writeln('            </ul>');
    }

    buffer.writeln('        </div>');
    buffer.writeln('    </div>');
    buffer.writeln('</body>');
    buffer.writeln('</html>');

    return buffer.toString();
  }

  String _getFileIcon(String extension) {
    switch (extension) {
      case '.jpg':
      case '.jpeg':
      case '.png':
      case '.gif':
      case '.bmp':
      case '.webp':
        return '🖼️';
      case '.mp4':
      case '.avi':
      case '.mov':
      case '.wmv':
      case '.flv':
        return '🎥';
      case '.mp3':
      case '.wav':
      case '.aac':
      case '.flac':
      case '.ogg':
        return '🎵';
      case '.pdf':
        return '📄';
      case '.doc':
      case '.docx':
        return '📝';
      case '.xls':
      case '.xlsx':
        return '📊';
      case '.ppt':
      case '.pptx':
        return '📈';
      case '.zip':
      case '.rar':
      case '.7z':
        return '🗜️';
      case '.txt':
        return '📋';
      default:
        return '📁';
    }
  }

  String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;');
  }
}
