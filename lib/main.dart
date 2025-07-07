import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'models/shared_file.dart';
import 'services/file_picker_service.dart';
import 'services/file_server_service.dart';
import 'services/nfc_service.dart';
import 'services/share_service.dart';
import 'dart:io';

void main() {
  runApp(const JustTouchApp());
}

class JustTouchApp extends StatelessWidget {
  const JustTouchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JustTouch',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF667eea),
          brightness: Brightness.light,
        ),
      ),
      home: const JustTouchHomePage(),
    );
  }
}

class JustTouchHomePage extends StatefulWidget {
  const JustTouchHomePage({super.key});

  @override
  State<JustTouchHomePage> createState() => _JustTouchHomePageState();
}

class _JustTouchHomePageState extends State<JustTouchHomePage> {
  final FileServerService _fileServer = FileServerService();
  List<SharedFile> _selectedFiles = [];
  bool _isNfcAvailable = false;
  bool _isHceSupported = false;
  bool _isDefaultService = false;
  bool _isSharing = false;
  String? _serverUrl;

  @override
  void initState() {
    super.initState();
    _checkNfcAvailability();
    _requestPermissions();
    _initializeShareService();
  }

  void _initializeShareService() {
    ShareService.initialize();
    ShareService.setOnFilesSharedCallback(_handleSharedFiles);
  }

  void _handleSharedFiles(List<SharedFile> sharedFiles) {
    setState(() {
      _selectedFiles = sharedFiles;
    });
    
    // Show a snackbar to indicate files were received
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Received ${sharedFiles.length} file${sharedFiles.length > 1 ? 's' : ''} to share',
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  void dispose() {
    _stopSharing();
    super.dispose();
  }

  Future<void> _checkNfcAvailability() async {
    final nfcAvailable = await NfcService.isNfcAvailable();
    final hceSupported = await NfcService.isHceSupported();
    
    setState(() {
      _isNfcAvailable = nfcAvailable;
      _isHceSupported = hceSupported;
      _isDefaultService = true; // Always true since we don't need to be default
    });
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.storage,
      Permission.photos,
      Permission.videos,
      Permission.audio,
    ].request();
  }

  Future<void> _pickFiles() async {
    final files = await FilePickerService.pickFiles();
    setState(() {
      _selectedFiles = files;
    });
  }

  Future<void> _startSharing() async {
    if (_selectedFiles.isEmpty) {
      _showMessage('Please select files to share first');
      return;
    }

    try {
      setState(() {
        _isSharing = true;
      });

      // Enable HCE first (this may prompt user to set as default service. it will not work if so)
      final hceEnabled = await NfcService.enableHce();
      if (!hceEnabled) {
        throw Exception('Failed to enable NFC service');
      }

      // Start the file server
      final serverUrl = await _fileServer.startServer(_selectedFiles);
      if (serverUrl == null) {
        throw Exception('Failed to start file server');
      }

      // Set up NFC with the server URL
      final nfcSuccess = await NfcService.setNfcUrl(serverUrl);
      if (!nfcSuccess) {
        throw Exception('Failed to set up NFC');
      }

      setState(() {
        _serverUrl = serverUrl;
        _isDefaultService = true;
      });

      _showMessage('Touch your phone to another device to share files!');
    } catch (e) {
      _showMessage('Error starting share: $e');
      setState(() {
        _isSharing = false;
      });
    }
  }

  Future<void> _startQrOnlySharing() async {
    if (_selectedFiles.isEmpty) {
      _showMessage('Please select files to share first');
      return;
    }

    try {
      setState(() {
        _isSharing = true;
      });

      // Start the file server (without NFC)
      final serverUrl = await _fileServer.startServer(_selectedFiles);
      if (serverUrl == null) {
        throw Exception('Failed to start file server');
      }

      setState(() {
        _serverUrl = serverUrl;
      });

      _showMessage('Server started! Use QR code to share files.');
      
      // Automatically show QR code
      _showQrCode();
    } catch (e) {
      _showMessage('Error starting share: $e');
      setState(() {
        _isSharing = false;
      });
    }
  }

  Future<void> _stopSharing() async {
    await _fileServer.stopServer();
    if (!Platform.isIOS) {
      await NfcService.disableHce();
    }
    setState(() {
      _isSharing = false;
      _serverUrl = null;
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  void _showQrCode() {
    if (_serverUrl == null) return;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '📱 Scan QR Code',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Scan this QR code with any camera app to access the files',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: QrImageView(
                    data: _serverUrl!,
                    version: QrVersions.auto,
                    size: 200.0,
                    backgroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _serverUrl!,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getButtonText() {
    if (_isSharing) {
      return 'Stop Sharing';
    } else if (!_isNfcAvailable) {
      return 'NFC Not Available';
    } else if (!_isHceSupported) {
      return 'HCE Not Supported';
    } else if (_selectedFiles.isEmpty) {
      return 'Select Files First';
    } else {
      return 'Touch to Send';
    }
  }

  Color _getNfcStatusColor() {
    if (_isNfcAvailable && _isHceSupported) {
      return Colors.green.shade50;
    } else if (_isNfcAvailable) {
      return Colors.orange.shade50;
    } else {
      return Colors.red.shade50;
    }
  }

  IconData _getNfcStatusIcon() {
    if (_isNfcAvailable && _isHceSupported) {
      return Icons.check_circle;
    } else if (_isNfcAvailable) {
      return Icons.info;
    } else {
      return Icons.warning;
    }
  }

  Color _getNfcStatusIconColor() {
    if (_isNfcAvailable && _isHceSupported) {
      return Colors.green;
    } else if (_isNfcAvailable) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  String _getNfcStatusText() {
    if (!_isNfcAvailable) {
      return 'NFC not available - QR code sharing available';
    } else if (!_isHceSupported) {
      return 'NFC available but HCE not supported - QR code available';
    } else if (_isDefaultService) {
      return 'NFC Ready for Sharing';
    } else if (_selectedFiles.isNotEmpty) {
      return 'Tap "Touch to Send" to setup NFC service';
    } else {
      return 'NFC available - Select files to begin sharing';
    }
  }

  Color _getNfcStatusTextColor() {
    if (_isNfcAvailable && _isHceSupported) {
      return Colors.green.shade700;
    } else if (_isNfcAvailable) {
      return Colors.orange.shade700;
    } else {
      return Colors.red.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const Icon(
                      Icons.touch_app,
                      size: 80,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'JustTouch',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w300,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'NFC File Sharing Made Simple',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      // NFC Status
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _getNfcStatusColor(),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(24),
                            topRight: Radius.circular(24),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _getNfcStatusIcon(),
                              color: _getNfcStatusIconColor(),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _getNfcStatusText(),
                                style: TextStyle(
                                  color: _getNfcStatusTextColor(),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // File List
                      Expanded(
                        child: _selectedFiles.isEmpty
                          ? _buildEmptyState()
                          : _buildFileList(),
                      ),
                      
                      // Action Buttons
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton.icon(
                                onPressed: _isSharing ? null : _pickFiles,
                                icon: const Icon(Icons.folder_open),
                                label: Text(_selectedFiles.isEmpty 
                                  ? 'Select Files' 
                                  : 'Select Different Files'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).colorScheme.surface,
                                  foregroundColor: Theme.of(context).colorScheme.primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: BorderSide(
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton.icon(
                                onPressed: _isSharing
                                    ? _stopSharing
                                    : (_selectedFiles.isEmpty || (!_isNfcAvailable || !_isHceSupported))
                                        ? null
                                        : _startSharing,
                                icon: Icon(_isSharing ? Icons.stop : Icons.nfc),
                                label: Text(_getButtonText()),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _isSharing 
                                    ? Colors.red.shade400 
                                    : Theme.of(context).colorScheme.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ),
                            // QR Code button - always visible when files are selected
                            if (_selectedFiles.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton.icon(
                                  onPressed: _isSharing ? _showQrCode : _startQrOnlySharing,
                                  icon: const Icon(Icons.qr_code),
                                  label: Text(_isSharing ? 'Show QR Code' : 'Share via QR Code'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange.shade400,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                            if (_isSharing && _serverUrl != null) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.info, color: Colors.blue.shade600),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Touch your phone to another device now...',
                                        style: TextStyle(
                                          color: Colors.blue.shade700,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No files selected',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap "Select Files" to choose files to share',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFileList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _selectedFiles.length,
      itemBuilder: (context, index) {
        final file = _selectedFiles[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Icon(
                _getFileIcon(file.fileName),
                color: Colors.white,
              ),
            ),
            title: Text(
              file.fileName,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text('${file.sizeFormatted} • ${file.mimeType}'),
            trailing: IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: _isSharing ? null : () {
                setState(() {
                  _selectedFiles.removeAt(index);
                });
              },
            ),
          ),
        );
      },
    );
  }

  IconData _getFileIcon(String fileName) {
    final extension = fileName.toLowerCase().split('.').last;
    switch (extension) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'bmp':
      case 'webp':
        return Icons.image;
      case 'mp4':
      case 'avi':
      case 'mov':
      case 'wmv':
      case 'flv':
        return Icons.video_file;
      case 'mp3':
      case 'wav':
      case 'aac':
      case 'flac':
      case 'ogg':
        return Icons.audio_file;
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'zip':
      case 'rar':
      case '7z':
        return Icons.archive;
      case 'txt':
        return Icons.text_snippet;
      default:
        return Icons.insert_drive_file;
    }
  }
}
