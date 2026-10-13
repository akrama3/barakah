import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/data.dart';

class TanyaAiScreen extends StatefulWidget {
  const TanyaAiScreen({super.key});

  @override
  State<TanyaAiScreen> createState() => _TanyaAiScreenState();
}

class _TanyaAiScreenState extends State<TanyaAiScreen> {
  final TextEditingController _pertanyaanController = TextEditingController();
  final List<Map<String, String>> pesan = [];
  bool loading = false;

  Future<String> _tanya(String pertanyaan) async {
    if (aiApiKey == 'ISI_API_KEY_DI_SINI') {
      return 'API key belum diisi. Isi aiApiKey di models/data.dart.';
    }
    try {
      final res = await http
          .post(
            Uri.parse('https://api.anthropic.com/v1/messages'),
            headers: {
              'content-type': 'application/json',
              'x-api-key': aiApiKey,
              'anthropic-version': '2023-06-01',
            },
            body: jsonEncode({
              'model': aiModel,
              'max_tokens': 600,
              'system': aiSystemPrompt,
              'messages': [
                {'role': 'user', 'content': pertanyaan},
              ],
            }),
          )
          .timeout(const Duration(seconds: 30));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['content'][0]['text'].toString();
      }
      return 'Gagal (kode ${res.statusCode}). Coba lagi.';
    } catch (e) {
      return 'Koneksi bermasalah. Periksa internet lalu kirim ulang.';
    }
  }

  Future<void> _kirim() async {
    String pertanyaan = _pertanyaanController.text.trim();
    if (pertanyaan.isEmpty || loading) return;
    setState(() {
      pesan.add({'role': 'user', 'text': pertanyaan});
      loading = true;
      _pertanyaanController.clear();
    });
    String jawaban = await _tanya(pertanyaan);
    if (!mounted) return;
    setState(() {
      pesan.add({'role': 'ai', 'text': '$jawaban\n\nCatatan: $aiDisclaimer'});
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tanya Fikih Dasar'),
        actions: [
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () {
              setState(() {
                pesan.clear();
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: pesan.isEmpty
                ? Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Tanyakan fikih dasar, misalnya: "Apa saja rukun wudhu?"',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.all(12),
                    itemCount: pesan.length,
                    itemBuilder: (context, index) {
                      bool dariUser = pesan[index]['role'] == 'user';
                      return Align(
                        alignment: dariUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: EdgeInsets.symmetric(vertical: 4),
                          padding: EdgeInsets.all(12),
                          constraints: BoxConstraints(maxWidth: 300),
                          decoration: BoxDecoration(
                            color: dariUser ? Colors.green.shade100 : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(pesan[index]['text']!),
                        ),
                      );
                    },
                  ),
          ),
          if (loading)
            Padding(
              padding: EdgeInsets.all(8),
              child: Text('Barakah AI sedang mengetik...'),
            ),
          Padding(
            padding: EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _pertanyaanController,
                    decoration: InputDecoration(
                      hintText: 'Ketik pertanyaan...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8.0)),
                      ),
                    ),
                  ),
                ),
                IconButton(icon: Icon(Icons.send), onPressed: _kirim),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
