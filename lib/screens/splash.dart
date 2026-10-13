import 'package:flutter/material.dart';
import '../models/db_helper.dart';
import '../models/helper.dart';
import '../root.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _cek();
  }

  void _keLogin() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  Future<void> _cek() async {
    String? username = await ambilSesi();
    Map<String, dynamic>? user =
        username == null ? null : await DbHelper.ambilUser(username);
    if (user == null) {
      _keLogin();
      return;
    }
    final Map<String, dynamic> u = user;

    // sesi ada: minta biometrik bila perangkat mendukung
    bool lolos = true;
    if (await biometrikTersedia()) {
      lolos = await verifikasiBiometrik();
    }
    if (!mounted) return;
    if (lolos) {
      final String uname = u['username'];
      final String nama = u['nama'];
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => Root(username: uname, nama: nama),
        ),
      );
    } else {
      _keLogin();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.nights_stay, size: 80, color: Colors.green),
            SizedBox(height: 12),
            Text(
              'Barakah',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
