import 'package:flutter/material.dart';
import 'models/helper.dart';
import 'screens/home.dart';
import 'screens/profile.dart';
import 'screens/saran.dart';
import 'screens/login_screen.dart';

class Root extends StatefulWidget {
  final String username;
  final String nama;
  const Root({super.key, required this.username, required this.nama});

  @override
  State<Root> createState() => _RootState();
}

class _RootState extends State<Root> {
  int _selectedIndex = 0;

  Future<void> _logout() async {
    await hapusSesi();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      HomeScreen(),
      ProfileScreen(username: widget.username, nama: widget.nama),
      SaranScreen(username: widget.username),
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          if (index == 3) {
            _logout();
          } else {
            setState(() {
              _selectedIndex = index;
            });
          }
        },
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Beranda'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
          BottomNavigationBarItem(icon: Icon(Icons.rate_review), label: 'Saran'),
          BottomNavigationBarItem(icon: Icon(Icons.logout), label: 'Logout'),
        ],
      ),
    );
  }
}
