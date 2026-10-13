import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data.dart';
import 'db_helper.dart';

// ====== ENKRIPSI PASSWORD (SHA-256 + salt) ======
String buatSalt() {
  final random = Random.secure();
  List<int> bytes = List<int>.generate(16, (i) => random.nextInt(256));
  return base64Url.encode(bytes);
}

String hashPassword(String password, String salt) {
  return sha256.convert(utf8.encode('$salt$password')).toString();
}

// ====== SESSION ======
Future<void> simpanSesi(String username) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('sesi_user', username);
  await prefs.setString('last_user', username);
}

Future<String?> ambilSesi() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('sesi_user');
}

Future<String?> ambilLastUser() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('last_user');
}

Future<void> hapusSesi() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('sesi_user');
}

// ====== BIOMETRIK ======
Future<bool> biometrikTersedia() async {
  try {
    final auth = LocalAuthentication();
    return await auth.isDeviceSupported();
  } catch (e) {
    return false;
  }
}

Future<bool> verifikasiBiometrik() async {
  try {
    final auth = LocalAuthentication();
    return await auth.authenticate(
      localizedReason: 'Verifikasi untuk masuk ke Barakah',
    );
  } catch (e) {
    return false;
  }
}

// ====== LOKASI (LBS) ======
Future<Position?> ambilLokasi() async {
  try {
    bool aktif = await Geolocator.isLocationServiceEnabled();
    if (!aktif) return null;
    LocationPermission izin = await Geolocator.checkPermission();
    if (izin == LocationPermission.denied) {
      izin = await Geolocator.requestPermission();
    }
    if (izin == LocationPermission.denied ||
        izin == LocationPermission.deniedForever) {
      return null;
    }
    return await Geolocator.getCurrentPosition();
  } catch (e) {
    return null;
  }
}

// ====== RUMUS KIBLAT & JARAK ======
double hitungKiblat(double lat, double lon) {
  double rad(double d) => d * pi / 180;
  double dLon = rad(kabahLon - lon);
  double y = sin(dLon) * cos(rad(kabahLat));
  double x = cos(rad(lat)) * sin(rad(kabahLat)) -
      sin(rad(lat)) * cos(rad(kabahLat)) * cos(dLon);
  return (atan2(y, x) * 180 / pi + 360) % 360;
}

// jarak dua titik dalam km (haversine)
double hitungJarak(double lat1, double lon1, double lat2, double lon2) {
  double rad(double d) => d * pi / 180;
  double dLat = rad(lat2 - lat1);
  double dLon = rad(lon2 - lon1);
  double a = sin(dLat / 2) * sin(dLat / 2) +
      cos(rad(lat1)) * cos(rad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
  return 6371 * 2 * atan2(sqrt(a), sqrt(1 - a));
}

// ====== ZONA WAKTU ======
// London: UTC+1 (BST) dari Minggu terakhir Maret sampai Minggu terakhir Oktober
int offsetLondon(DateTime d) {
  DateTime terakhirMinggu(int tahun, int bulan) {
    DateTime akhir = DateTime.utc(tahun, bulan + 1, 0);
    return akhir.subtract(Duration(days: akhir.weekday % 7));
  }

  DateTime mulai = terakhirMinggu(d.year, 3).add(Duration(hours: 1));
  DateTime selesai = terakhirMinggu(d.year, 10).add(Duration(hours: 1));
  DateTime sekarang = d.toUtc();
  return (sekarang.isAfter(mulai) && sekarang.isBefore(selesai)) ? 1 : 0;
}

int offsetZona(String nama, DateTime d) {
  if (nama == 'WIB') return 7;
  if (nama == 'WITA') return 8;
  if (nama == 'WIT') return 9;
  return offsetLondon(d);
}

String konversiWaktu(String hhmm, int offsetAsal, int offsetTujuan) {
  List<String> p = hhmm.split(':');
  int menit = int.parse(p[0]) * 60 + int.parse(p[1]);
  int total = menit + (offsetTujuan - offsetAsal) * 60;
  String hari = '';
  if (total >= 1440) hari = ' (+1 hari)';
  if (total < 0) hari = ' (-1 hari)';
  total = total % 1440;
  String jam = (total ~/ 60).toString().padLeft(2, '0');
  String mnt = (total % 60).toString().padLeft(2, '0');
  return '$jam:$mnt$hari';
}

// ====== API JADWAL SHOLAT (Aladhan, method 20 = Kemenag RI) ======
Future<JadwalHasil?> ambilJadwal(double lat, double lon) async {
  final prefs = await SharedPreferences.getInstance();
  try {
    final res = await http
        .get(Uri.parse(
            'https://api.aladhan.com/v1/timings?latitude=$lat&longitude=$lon&method=20'))
        .timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) {
      final t = jsonDecode(res.body)['data']['timings'];
      Map<String, String> waktu = {
        'Subuh': t['Fajr'].toString().substring(0, 5),
        'Terbit': t['Sunrise'].toString().substring(0, 5),
        'Dzuhur': t['Dhuhr'].toString().substring(0, 5),
        'Ashar': t['Asr'].toString().substring(0, 5),
        'Maghrib': t['Maghrib'].toString().substring(0, 5),
        'Isya': t['Isha'].toString().substring(0, 5),
      };
      await prefs.setString('jadwal_cache', jsonEncode(waktu));
      return JadwalHasil(waktu: waktu, offline: false);
    }
  } catch (e) {
    // lanjut ke cache
  }
  String? cache = prefs.getString('jadwal_cache');
  if (cache != null) {
    Map<String, dynamic> m = jsonDecode(cache);
    return JadwalHasil(
      waktu: m.map((k, v) => MapEntry(k, v.toString())),
      offline: true,
    );
  }
  return null;
}

// ====== API KURS ======
Future<KursHasil> ambilKurs() async {
  final prefs = await SharedPreferences.getInstance();
  try {
    final res = await http
        .get(Uri.parse('https://open.er-api.com/v6/latest/USD'))
        .timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) {
      final rates = jsonDecode(res.body)['rates'];
      Map<String, double> kurs = {
        'USD': 1.0,
        'IDR': (rates['IDR'] as num).toDouble(),
        'SAR': (rates['SAR'] as num).toDouble(),
      };
      String waktu = DateTime.now().toString().substring(0, 16);
      await prefs.setString('kurs_cache', jsonEncode({'kurs': kurs, 'waktu': waktu}));
      return KursHasil(kurs: kurs, waktu: waktu, offline: false);
    }
  } catch (e) {
    // lanjut ke cache
  }
  String? cache = prefs.getString('kurs_cache');
  if (cache != null) {
    Map<String, dynamic> c = jsonDecode(cache);
    Map<String, dynamic> k = c['kurs'];
    return KursHasil(
      kurs: k.map((a, b) => MapEntry(a, (b as num).toDouble())),
      waktu: c['waktu'].toString(),
      offline: true,
    );
  }
  return KursHasil(
    kurs: {'USD': 1.0, 'IDR': 16500.0, 'SAR': 3.75},
    waktu: 'data bawaan (offline)',
    offline: true,
  );
}

double konversiUang(double x, String dari, String ke, Map<String, double> kurs) {
  return x / kurs[dari]! * kurs[ke]!;
}

String formatUang(double v, String mataUang) {
  if (mataUang == 'IDR') {
    String s = v.round().toString().replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (m) => '.',
        );
    return 'Rp $s';
  }
  return '${v.toStringAsFixed(2)} $mataUang';
}

// ====== BLOCKCHAIN SEDERHANA (hash chain SHA-256) ======
String hitungHashBlok(Block b) {
  String data =
      '${b.idx}|${b.timestamp}|${b.donorAlias}|${b.campaign}|${b.amount}|${b.currency}|${b.amountIdr}|${b.rateUsed}|${b.prevHash}';
  return sha256.convert(utf8.encode(data)).toString();
}

Future<Block> buatBlokDonasi({
  required String alias,
  required String campaign,
  required double amount,
  required String currency,
  required double amountIdr,
  required double rate,
}) async {
  List<Block> daftar = await DbHelper.ambilBlok();
  if (daftar.isEmpty) {
    Block genesis = Block(
      idx: 0,
      timestamp: DateTime.now().toUtc().toIso8601String(),
      donorAlias: 'GENESIS',
      campaign: 'GENESIS',
      amount: 0,
      currency: 'IDR',
      amountIdr: 0,
      rateUsed: 1,
      prevHash: '0',
      hash: '',
    );
    genesis.hash = hitungHashBlok(genesis);
    await DbHelper.simpanBlok(genesis);
    daftar = [genesis];
  }
  Block terakhir = daftar.last;
  Block baru = Block(
    idx: terakhir.idx + 1,
    timestamp: DateTime.now().toUtc().toIso8601String(),
    donorAlias: alias,
    campaign: campaign,
    amount: amount,
    currency: currency,
    amountIdr: amountIdr,
    rateUsed: rate,
    prevHash: terakhir.hash,
    hash: '',
  );
  baru.hash = hitungHashBlok(baru);
  await DbHelper.simpanBlok(baru);
  return baru;
}

// ====== NOTIFIKASI LOKAL ======
final FlutterLocalNotificationsPlugin notifPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> initNotif() async {
  try {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await notifPlugin.initialize(const InitializationSettings(android: android));
    await notifPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  } catch (e) {
    // abaikan agar aplikasi tetap jalan
  }
}

Future<void> tampilNotif(String judul, String isi) async {
  try {
    const detail = NotificationDetails(
      android: AndroidNotificationDetails(
        'adzan_channel',
        'Pengingat Adzan',
        importance: Importance.max,
        priority: Priority.high,
      ),
    );
    await notifPlugin.show(0, judul, isi, detail);
  } catch (e) {
    // abaikan
  }
}
