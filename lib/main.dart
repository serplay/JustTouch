import 'package:flutter/material.dart';
import 'receive_page.dart';
import 'send_page.dart';

void main() {
  runApp(const JustTouchApp());
}

class JustTouchApp extends StatelessWidget {
  const JustTouchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const MainNavigation(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  static final List<Widget> _pages = <Widget>[
    ReceivePage(),
    SendPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Column(
              children: [
                Icon(Icons.download),
                SizedBox(height: 2),
              ],
            ),
            label: 'Receive',
          ),
          BottomNavigationBarItem(
            icon: Column(
              children: [
                Icon(Icons.send),
                SizedBox(height: 2),
              ],
            ),
            label: 'Send',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
