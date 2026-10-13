// ====== KONFIGURASI ======
// ISI API key LLM kamu di sini (hanya untuk demo tugas, jangan di-commit ke GitHub publik)
const String aiApiKey = 'ISI_API_KEY_DI_SINI';
const String aiModel = 'claude-haiku-4-5-20251001';
const String aiSystemPrompt =
    'Kamu adalah asisten fikih dasar bernama Barakah AI. '
    'Jawab dalam bahasa Indonesia secara singkat dan terstruktur. '
    'Batasi pada fikih dasar (wudhu, sholat, puasa, zakat). '
    'Sebutkan perbedaan pendapat antar mazhab bila relevan. '
    'Jangan mengeluarkan fatwa. Jika pertanyaan di luar cakupan atau kasus pribadi '
    'yang kompleks, tolak dengan sopan dan sarankan bertanya kepada ulama.';
const String aiDisclaimer =
    'Ini informasi umum, konsultasikan dengan ulama atau ustadz untuk kasus spesifik.';

const double kabahLat = 21.4225;
const double kabahLon = 39.8262;
const double defaultLat = -7.7956; // Yogyakarta
const double defaultLon = 110.3695;

const List<String> namaSholat = [
  'Subuh',
  'Terbit',
  'Dzuhur',
  'Ashar',
  'Maghrib',
  'Isya',
];
const List<String> daftarZona = ['WIB', 'WITA', 'WIT', 'London'];
const List<String> daftarMataUang = ['IDR', 'USD', 'SAR'];
const List<String> daftarKampanye = [
  'Pembangunan Masjid',
  'Beasiswa Santri',
  'Bantuan Pangan',
  'Sumur Wakaf',
];

// ====== MODEL ======
class Block {
  int idx;
  String timestamp;
  String donorAlias;
  String campaign;
  double amount;
  String currency;
  double amountIdr;
  double rateUsed;
  String prevHash;
  String hash;

  Block({
    required this.idx,
    required this.timestamp,
    required this.donorAlias,
    required this.campaign,
    required this.amount,
    required this.currency,
    required this.amountIdr,
    required this.rateUsed,
    required this.prevHash,
    required this.hash,
  });

  Map<String, dynamic> toMap() {
    return {
      'idx': idx,
      'timestamp': timestamp,
      'donor_alias': donorAlias,
      'campaign': campaign,
      'amount': amount,
      'currency': currency,
      'amount_idr': amountIdr,
      'rate_used': rateUsed,
      'prev_hash': prevHash,
      'hash': hash,
    };
  }

  factory Block.fromMap(Map<String, dynamic> m) {
    return Block(
      idx: m['idx'] as int,
      timestamp: m['timestamp'] as String,
      donorAlias: m['donor_alias'] as String,
      campaign: m['campaign'] as String,
      amount: (m['amount'] as num).toDouble(),
      currency: m['currency'] as String,
      amountIdr: (m['amount_idr'] as num).toDouble(),
      rateUsed: (m['rate_used'] as num).toDouble(),
      prevHash: m['prev_hash'] as String,
      hash: m['hash'] as String,
    );
  }
}

class JadwalHasil {
  Map<String, String> waktu;
  bool offline;
  JadwalHasil({required this.waktu, required this.offline});
}

class KursHasil {
  Map<String, double> kurs; // nilai per 1 USD
  String waktu;
  bool offline;
  KursHasil({required this.kurs, required this.waktu, required this.offline});
}

class Masjid {
  String nama;
  String alamat;
  double lat;
  double lon;
  Masjid({
    required this.nama,
    required this.alamat,
    required this.lat,
    required this.lon,
  });
}

class Question {
  String pertanyaan;
  List<String> opsi;
  int jawaban;
  String penjelasan;
  Question({
    required this.pertanyaan,
    required this.opsi,
    required this.jawaban,
    required this.penjelasan,
  });
}

// ====== DATA DUMMY ======
// Koordinat perkiraan, hanya contoh. Ganti/tambah sesuai kebutuhan.
final List<Masjid> daftarMasjid = [
  Masjid(nama: 'Masjid Gedhe Kauman', alamat: 'Kauman, Yogyakarta', lat: -7.8052, lon: 110.3637),
  Masjid(nama: 'Masjid Jogokariyan', alamat: 'Mantrijeron, Yogyakarta', lat: -7.8130, lon: 110.3623),
  Masjid(nama: 'Masjid Syuhada', alamat: 'Kotabaru, Yogyakarta', lat: -7.7835, lon: 110.3748),
  Masjid(nama: 'Masjid Kampus UGM', alamat: 'Bulaksumur, Sleman', lat: -7.7714, lon: 110.3787),
];

final List<Question> soalKuis = [
  Question(
    pertanyaan: 'Berapa jumlah rukun Islam?',
    opsi: ['3', '4', '5', '6'],
    jawaban: 2,
    penjelasan: 'Syahadat, sholat, zakat, puasa Ramadhan, dan haji.',
  ),
  Question(
    pertanyaan: 'Berapa jumlah rukun iman?',
    opsi: ['4', '5', '6', '7'],
    jawaban: 2,
    penjelasan: 'Iman kepada Allah, malaikat, kitab, rasul, hari akhir, dan qada qadar.',
  ),
  Question(
    pertanyaan: 'Berapa kali sholat fardhu dalam sehari semalam?',
    opsi: ['3', '4', '5', '6'],
    jawaban: 2,
    penjelasan: 'Subuh, Dzuhur, Ashar, Maghrib, dan Isya.',
  ),
  Question(
    pertanyaan: 'Pada bulan apa umat Islam wajib berpuasa?',
    opsi: ['Rajab', 'Sya\'ban', 'Ramadhan', 'Syawal'],
    jawaban: 2,
    penjelasan: 'Puasa wajib dilakukan pada bulan Ramadhan.',
  ),
  Question(
    pertanyaan: 'Siapa nabi terakhir?',
    opsi: ['Nabi Isa', 'Nabi Musa', 'Nabi Muhammad SAW', 'Nabi Ibrahim'],
    jawaban: 2,
    penjelasan: 'Nabi Muhammad SAW adalah penutup para nabi.',
  ),
  Question(
    pertanyaan: 'Kitab Zabur diturunkan kepada nabi siapa?',
    opsi: ['Nabi Daud', 'Nabi Musa', 'Nabi Isa', 'Nabi Muhammad'],
    jawaban: 0,
    penjelasan: 'Zabur diturunkan kepada Nabi Daud AS.',
  ),
  Question(
    pertanyaan: 'Ke arah mana umat Islam menghadap saat sholat?',
    opsi: ['Masjidil Aqsa', 'Ka\'bah di Makkah', 'Masjid Nabawi', 'Gunung Uhud'],
    jawaban: 1,
    penjelasan: 'Kiblat umat Islam adalah Ka\'bah di Masjidil Haram, Makkah.',
  ),
  Question(
    pertanyaan: 'Surah pembuka dalam Al-Qur\'an adalah?',
    opsi: ['Al-Baqarah', 'Al-Fatihah', 'An-Nas', 'Al-Ikhlas'],
    jawaban: 1,
    penjelasan: 'Al-Fatihah berarti pembukaan.',
  ),
  Question(
    pertanyaan: 'Siapa khalifah pertama setelah wafatnya Rasulullah?',
    opsi: ['Umar bin Khattab', 'Utsman bin Affan', 'Abu Bakar Ash-Shiddiq', 'Ali bin Abi Thalib'],
    jawaban: 2,
    penjelasan: 'Abu Bakar Ash-Shiddiq menjadi khalifah pertama.',
  ),
  Question(
    pertanyaan: 'Nabi Muhammad SAW berhijrah dari Makkah ke kota?',
    opsi: ['Madinah', 'Thaif', 'Jeddah', 'Yerusalem'],
    jawaban: 0,
    penjelasan: 'Hijrah ke Madinah (dahulu Yatsrib) menjadi awal tahun Hijriyah.',
  ),
];
