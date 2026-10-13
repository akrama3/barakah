import 'package:flutter/material.dart';
import '../models/db_helper.dart';

class SaranScreen extends StatefulWidget {
  final String username;
  const SaranScreen({super.key, required this.username});

  @override
  State<SaranScreen> createState() => _SaranScreenState();
}

class _SaranScreenState extends State<SaranScreen> {
  final TextEditingController _saranController = TextEditingController();
  final TextEditingController _kesanController = TextEditingController();
  List<Map<String, dynamic>> daftar = [];

  @override
  void initState() {
    super.initState();
    _muat();
  }

  Future<void> _muat() async {
    final data = await DbHelper.ambilSaran(widget.username);
    if (!mounted) return;
    setState(() {
      daftar = data;
    });
  }

  Future<void> _kirim() async {
    String saran = _saranController.text.trim();
    String kesan = _kesanController.text.trim();
    if (saran.isEmpty || kesan.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saran dan kesan harus diisi'), backgroundColor: Colors.red),
      );
      return;
    }
    await DbHelper.simpanSaran(widget.username, saran, kesan);
    _saranController.clear();
    _kesanController.clear();
    _muat();
  }

  Widget _inputField(TextEditingController controller, String hint) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        maxLines: 3,
        decoration: InputDecoration(
          hintText: hint,
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
      appBar: AppBar(title: Text('Saran & Kesan')),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          Text('Mata kuliah Pemrograman Aplikasi Mobile'),
          _inputField(_saranController, 'Saran'),
          _inputField(_kesanController, 'Kesan'),
          ElevatedButton(onPressed: _kirim, child: Text('Kirim')),
          Divider(height: 32),
          Text('Riwayat', style: TextStyle(fontWeight: FontWeight.bold)),
          ...daftar.map(
            (s) => Card(
              child: ListTile(
                title: Text('Saran: ${s['saran']}'),
                subtitle: Text('Kesan: ${s['kesan']}\n${s['waktu']}'),
                isThreeLine: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
