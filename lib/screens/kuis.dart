import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/data.dart';

class KuisScreen extends StatefulWidget {
  const KuisScreen({super.key});

  @override
  State<KuisScreen> createState() => _KuisScreenState();
}

class _KuisScreenState extends State<KuisScreen> {
  late List<Question> soal;
  int index = 0;
  int skor = 0;
  int waktu = 20;
  int? dijawab; // null = belum, -1 = waktu habis
  bool selesai = false;
  int terbaik = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _mulai();
    _muatTerbaik();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _muatTerbaik() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      terbaik = prefs.getInt('kuis_terbaik') ?? 0;
    });
  }

  void _mulai() {
    soal = List.of(soalKuis);
    soal.shuffle();
    index = 0;
    skor = 0;
    dijawab = null;
    selesai = false;
    _mulaiTimer();
  }

  void _mulaiTimer() {
    _timer?.cancel();
    waktu = 20;
    _timer = Timer.periodic(Duration(seconds: 1), (t) {
      if (waktu <= 1) {
        t.cancel();
        setState(() {
          waktu = 0;
          dijawab = -1;
        });
      } else {
        setState(() {
          waktu--;
        });
      }
    });
  }

  void _pilih(int i) {
    if (dijawab != null) return;
    _timer?.cancel();
    setState(() {
      dijawab = i;
      if (i == soal[index].jawaban) skor += 10;
    });
  }

  Future<void> _lanjut() async {
    if (index < soal.length - 1) {
      setState(() {
        index++;
        dijawab = null;
      });
      _mulaiTimer();
    } else {
      final prefs = await SharedPreferences.getInstance();
      if (skor > terbaik) {
        await prefs.setInt('kuis_terbaik', skor);
        terbaik = skor;
      }
      if (!mounted) return;
      setState(() {
        selesai = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (selesai) {
      return Scaffold(
        appBar: AppBar(title: Text('Kuis Islami')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Kuis selesai', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              SizedBox(height: 12),
              Text('Skor: $skor', style: TextStyle(fontSize: 32)),
              Text('Jawaban benar: ${skor ~/ 10} dari ${soal.length}'),
              Text('Skor tertinggi: $terbaik'),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _mulai();
                  });
                },
                child: Text('Main lagi'),
              ),
            ],
          ),
        ),
      );
    }

    Question q = soal[index];
    return Scaffold(
      appBar: AppBar(title: Text('Soal ${index + 1}/${soal.length}')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Waktu: $waktu detik'),
                Text('Skor: $skor'),
              ],
            ),
            SizedBox(height: 16),
            Text(q.pertanyaan, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            for (int i = 0; i < q.opsi.length; i++)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: ElevatedButton(
                  onPressed: () => _pilih(i),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 48),
                    backgroundColor: dijawab == null
                        ? null
                        : (i == q.jawaban
                            ? Colors.green
                            : (i == dijawab ? Colors.red : null)),
                  ),
                  child: Text(q.opsi[i]),
                ),
              ),
            if (dijawab != null) ...[
              SizedBox(height: 12),
              Text(
                dijawab == -1
                    ? 'Waktu habis. ${q.penjelasan}'
                    : (dijawab == q.jawaban ? 'Benar! ${q.penjelasan}' : 'Salah. ${q.penjelasan}'),
              ),
              SizedBox(height: 12),
              Center(
                child: ElevatedButton(
                  onPressed: _lanjut,
                  child: Text(index < soal.length - 1 ? 'Lanjut' : 'Lihat hasil'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
