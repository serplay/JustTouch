import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  String receivedFileName = '';
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _receiveFile() {
    setState(() {
      receivedFileName = _controller.text;
    });
    // Tu można dodać logikę odbierania pliku
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Received file: $receivedFileName')),
    );
  }

  void _sendFile() {
    // Tu można dodać logikę wysyłania pliku
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('File sent!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('JustTouch'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Name of the file to receive',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _receiveFile,
              child: Text('Receive file'),
            ),
            SizedBox(height: 32),
            ElevatedButton(
              onPressed: _sendFile,
              child: Text('Send File'),
            ),
          ],
        ),
      ),
    );
  }
} 