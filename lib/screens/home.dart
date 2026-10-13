import 'dart:async';
import 'package:flutter/material.dart';
import '../models/data.dart';
import '../models/helper.dart';
import 'zona_waktu.dart';
import 'kiblat.dart';
import 'tasbih.dart';
import 'masjid.dart';
import 'donasi.dart';
import 'ledger.dart';
import 'tanya_ai.dart';
import 'kuis.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, String>? jadwal;
  bool offline = false;
  bool loading = true;
  String lokasi = '';
  String? nextName;
  String nextTime = '';
  String countdown = '--:--:--';
  bool notifAktif = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _muat();
    _timer = Timer.periodic(Duration(seconds: 1), (t) {
      _hitungBerikutnya();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _muat() async {
    setState(() {
      loading = true;
    });
    final pos = await ambilLokasi();
    double lat = pos?.latitude ?? defaultLat;
    double lon = pos?.longitude ?? defaultLon;
    JadwalHasil? hasil = await ambilJadwal(lat, lon);
    if (!mounted) return;
    setState(() {
      loading = false;
      lokasi = pos == null
          ? 'Lokasi default: Yogyakarta'
          : 'Lat ${lat.toStringAsFixed(3)}, Lon ${lon.toStringAsFixed(3)}';
      jadwal = hasil?.waktu;
      offline = hasil?.offline ?? false;
    });
    _hitungBerikutnya();
  }

  void _hitungBerikutnya() {
    if (jadwal == null || !mounted) return;
    DateTime now = DateTime.now();
    List<String> sholat = ['Subuh', 'Dzuhur', 'Ashar', 'Maghrib', 'Isya'];

    // default: Subuh besok, lalu cari sholat berikutnya hari ini
    List<String> ps = jadwal!['Subuh']!.split(':');
    String ketemu = 'Subuh';
    DateTime waktuKetemu = DateTime(
      now.year, now.month, now.day + 1, int.parse(ps[0]), int.parse(ps[1]),
    );
    for (String nama in sholat) {
      List<String> p = jadwal![nama]!.split(':');
      DateTime w = DateTime(
        now.year, now.month, now.day, int.parse(p[0]), int.parse(p[1]),
      );
      if (w.isAfter(now)) {
        ketemu = nama;
        waktuKetemu = w;
        break;
      }
    }

    Duration sisa = waktuKetemu.difference(now);
    String jam = sisa.inHours.toString().padLeft(2, '0');
    String menit = (sisa.inMinutes % 60).toString().padLeft(2, '0');
    String detik = (sisa.inSeconds % 60).toString().padLeft(2, '0');

    // sholat berganti = waktu sholat sebelumnya sudah tiba
    if (nextName != null && nextName != ketemu && notifAktif) {
      tampilNotif('Waktu $nextName telah tiba', 'Saatnya menunaikan sholat $nextName');
    }

    setState(() {
      nextName = ketemu;
      nextTime = jadwal![ketemu]!;
      countdown = '$jam:$menit:$detik';
    });
  }

  Widget _menu(IconData icon, String judul, String sub, Widget screen) {
    return ListTile(
      leading: Icon(icon, color: Colors.green),
      title: Text(judul),
      subtitle: Text(sub),
      trailing: Icon(Icons.arrow_forward_ios),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => screen),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Barakah'),
        actions: [
          IconButton(
            icon: Icon(notifAktif
                ? Icons.notifications_active
                : Icons.notifications_off),
            onPressed: () {
              setState(() {
                notifAktif = !notifAktif;
              });
            },
          ),
          IconButton(icon: Icon(Icons.refresh), onPressed: _muat),
        ],
      ),
      body: ListView(
        children: [
          if (loading)
            Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (jadwal == null)
            Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                children: [
                  Text('Jadwal gagal dimuat. Periksa koneksi internet.'),
                  SizedBox(height: 8),
                  ElevatedButton(onPressed: _muat, child: Text('Coba lagi')),
                ],
              ),
            )
          else ...[
            Card(
              margin: EdgeInsets.all(12),
              color: Colors.green.shade50,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(lokasi, style: TextStyle(color: Colors.grey)),
                    if (offline)
                      Text('Data offline (dari cache)',
                          style: TextStyle(color: Colors.orange)),
                    SizedBox(height: 8),
                    Text('Sholat berikutnya'),
                    Text(
                      '${nextName ?? '-'}  $nextTime',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    Text('dalam $countdown', style: TextStyle(fontSize: 18)),
                  ],
                ),
              ),
            ),
            for (String nama in namaSholat)
              ListTile(
                leading: Icon(Icons.access_time),
                title: Text(nama),
                tileColor: nama == nextName ? Colors.green.shade100 : null,
                trailing: Text(
                  jadwal![nama] ?? '-',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            TextButton(
              onPressed: () {
                tampilNotif('Tes Barakah', 'Notifikasi pengingat adzan berfungsi');
              },
              child: Text('Tes notifikasi'),
            ),
          ],
          Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Text(
              'Fitur',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          if (jadwal != null)
            _menu(Icons.schedule, 'Konversi Zona Waktu',
                'WIB, WITA, WIT, London', ZonaWaktuScreen(jadwal: jadwal!)),
          _menu(Icons.explore, 'Arah Kiblat', 'Kompas magnetometer', KiblatScreen()),
          _menu(Icons.touch_app, 'Tasbih Digital', 'Goyang untuk menghitung', TasbihScreen()),
          _menu(Icons.place, 'Masjid Terdekat', 'Cari dan lihat jarak', MasjidScreen()),
          _menu(Icons.favorite, 'Zakat & Donasi', 'IDR, USD, SAR', DonasiScreen()),
          _menu(Icons.link, 'Ledger Donasi', 'Rantai hash SHA-256', LedgerScreen()),
          _menu(Icons.chat, 'Tanya Fikih Dasar', 'Asisten AI', TanyaAiScreen()),
          _menu(Icons.help, 'Kuis Islami', '10 soal, 20 detik per soal', KuisScreen()),
          SizedBox(height: 16),
        ],
      ),
    );
  }
}
