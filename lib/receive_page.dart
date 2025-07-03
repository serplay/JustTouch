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
      NFCTag tag = await FlutterNfcKit.poll();
      if (tag.ndefAvailable == true) {
        final ndef = await FlutterNfcKit.readNDEFRecords();
        if (ndef.isNotEmpty && ndef.first.payload != null) {
          final payload = ndef.first.payload;
          final message = String.fromCharCodes(payload?.toList() ?? []);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Received: $message')),
            );
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
            const SnackBar(content: Text('Tag does not support NDEF.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('NFC error: $e')),
        );
      }
    } finally {
      await FlutterNfcKit.finish();
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