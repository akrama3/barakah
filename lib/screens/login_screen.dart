import 'package:flutter/material.dart';
import '../models/db_helper.dart';
import '../models/helper.dart';
import '../root.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool isLoginFailed = false;

  void _snack(String pesan) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(pesan), backgroundColor: Colors.red),
    );
  }

  void _masuk(String username, String nama) {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => Root(username: username, nama: nama),
      ),
    );
  }

  Future<void> _login() async {
    String username = _usernameController.text.trim();
    String password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      setState(() {
        isLoginFailed = true;
      });
      _snack('Username dan password tidak boleh kosong');
      return;
    }

    final user = await DbHelper.ambilUser(username);
    if (user == null ||
        hashPassword(password, user['salt']) != user['password_hash']) {
      setState(() {
        isLoginFailed = true;
      });
      _snack('Login gagal: username atau password salah');
      return;
    }

    final String nama = user['nama'];
    await simpanSesi(username);
    _masuk(username, nama);
  }

  Future<void> _loginBiometrik() async {
    String? last = await ambilLastUser();
    if (last == null) {
      _snack('Login dengan password sekali dulu agar biometrik bisa dipakai');
      return;
    }
    if (!await biometrikTersedia()) {
      _snack('Biometrik tidak tersedia di perangkat ini');
      return;
    }
    bool ok = await verifikasiBiometrik();
    if (!ok) {
      _snack('Verifikasi biometrik gagal');
      return;
    }
    final user = await DbHelper.ambilUser(last);
    if (user == null) {
      _snack('Akun tidak ditemukan');
      return;
    }
    final String nama = user['nama'];
    await simpanSesi(last);
    _masuk(last, nama);
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    bool obscure = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          hintText: hint,
          contentPadding: EdgeInsets.all(8.0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(8.0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(8.0)),
            borderSide: BorderSide(
              color: isLoginFailed ? Colors.red : Colors.green,
              width: 2.0,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login Barakah', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.nights_stay, size: 80, color: Colors.green),
              Text(
                'Barakah',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Text('Jadwal Sholat, Kiblat & Donasi'),
              SizedBox(height: 20),
              _inputField(controller: _usernameController, hint: 'Username'),
              _inputField(
                controller: _passwordController,
                hint: 'Password',
                obscure: true,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  minimumSize: Size(200, 45),
                ),
                child: Text('Login'),
              ),
              SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _loginBiometrik,
                icon: Icon(Icons.fingerprint),
                label: Text('Masuk dengan Biometrik'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => RegisterScreen()),
                  );
                },
                child: Text('Belum punya akun? Daftar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
