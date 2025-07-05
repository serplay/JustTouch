import 'package:flutter/material.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';

class ReceivePage extends StatefulWidget {
  const ReceivePage({super.key});

  @override
  State<ReceivePage> createState() => _ReceivePageState();
}

class _ReceivePageState extends State<ReceivePage> {
  bool _isListening = false;

  Future<void> _listenNFC() async {
    setState(() {
      _isListening = true;
    });
    
    try {
      // Check if NFC is available
      final availability = await FlutterNfcKit.nfcAvailability;
      if (availability != NFCAvailability.available) {
        throw Exception('NFC is not available on this device');
      }
      
      NFCTag tag = await FlutterNfcKit.poll();
      
      // Try to read NDEF records
      if (tag.ndefAvailable == true) {
        final ndef = await FlutterNfcKit.readNDEFRecords();
        if (ndef.isNotEmpty) {
          final record = ndef.first;
          if (record.payload != null && record.payload!.isNotEmpty) {
            try {
              // Handle text records properly
              final payload = record.payload!;
              String message;
              
              // For text records, skip the first few bytes which contain encoding info
              if (record.type != null && record.type!.isNotEmpty) {
                // This is likely a text record, skip the language code prefix
                final languageCodeLength = payload.isNotEmpty ? payload[0] & 0x3F : 0;
                final startIndex = 1 + languageCodeLength;
                if (startIndex < payload.length) {
                  message = String.fromCharCodes(payload.sublist(startIndex));
                } else {
                  message = String.fromCharCodes(payload);
                }
              } else {
                message = String.fromCharCodes(payload);
              }
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Received: $message')),
                );
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error reading message: $e')),
                );
              }
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No data on the tag.')),
              );
            }
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No NDEF records found.')),
            );
          }
        }
      } else {
        // Try to read raw data if NDEF is not available
        try {
          // Get tag info
          final tagInfo = tag.toString();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Tag detected: $tagInfo')),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error reading tag: $e')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('NFC error: $e')),
        );
      }
    } finally {
      try {
        await FlutterNfcKit.finish();
      } catch (e) {
        // Ignore finish errors
      }
      if (mounted) {
        setState(() {
          _isListening = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Receive through NFC'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.download, size: 64),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isListening ? null : _listenNFC,
              icon: const Icon(Icons.nfc),
              label: Text(_isListening ? 'Listening...' : 'Receive through NFC'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 