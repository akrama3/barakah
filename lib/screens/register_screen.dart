import 'package:flutter/material.dart';
import '../models/db_helper.dart';
import '../models/helper.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  void _snack(String pesan, {bool error = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(pesan),
        backgroundColor: error ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> _daftar() async {
    String nama = _namaController.text.trim();
    String username = _usernameController.text.trim();
    String password = _passwordController.text;

    if (nama.isEmpty || username.isEmpty || password.isEmpty) {
      _snack('Semua kolom harus diisi');
      return;
    }
    if (password.length < 6) {
      _snack('Password minimal 6 karakter');
      return;
    }
    if (await DbHelper.ambilUser(username) != null) {
      _snack('Username sudah dipakai');
      return;
    }

    // password disimpan sebagai hash (SHA-256 + salt), bukan teks asli
    String salt = buatSalt();
    await DbHelper.simpanUser(username, nama, salt, hashPassword(password, salt));
    _snack('Pendaftaran berhasil, silakan login', error: false);
    if (!mounted) return;
    Navigator.pop(context);
  }

  Widget _inputField(TextEditingController controller, String hint,
      {bool obscure = false}) {
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
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Daftar Akun')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            _inputField(_namaController, 'Nama lengkap'),
            _inputField(_usernameController, 'Username'),
            _inputField(_passwordController, 'Password (min. 6 karakter)',
                obscure: true),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _daftar,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                minimumSize: Size(200, 45),
              ),
              child: Text('Daftar'),
            ),
          ],
        ),
      ),
    );
  }
}
