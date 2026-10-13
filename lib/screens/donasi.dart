import 'package:flutter/material.dart';
import '../models/data.dart';
import '../models/helper.dart';

class DonasiScreen extends StatefulWidget {
  const DonasiScreen({super.key});

  @override
  State<DonasiScreen> createState() => _DonasiScreenState();
}

class _DonasiScreenState extends State<DonasiScreen> {
  final TextEditingController _nominalController = TextEditingController();
  final TextEditingController _emasController = TextEditingController(text: '2000000');
  final TextEditingController _aliasController = TextEditingController(text: 'Hamba Allah');
  String mode = 'Zakat';
  String mataUang = 'IDR';
  String kampanye = daftarKampanye[0];
  KursHasil? kursHasil;
  String hasil = '';

  @override
  void initState() {
    super.initState();
    _muatKurs();
  }

  Future<void> _muatKurs() async {
    KursHasil k = await ambilKurs();
    if (!mounted) return;
    setState(() {
      kursHasil = k;
    });
  }

  void _snack(String pesan) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(pesan), backgroundColor: Colors.red),
    );
  }

  String _setara(double nilai) {
    final kurs = kursHasil!.kurs;
    return daftarMataUang
        .where((c) => c != mataUang)
        .map((c) => formatUang(konversiUang(nilai, mataUang, c, kurs), c))
        .join('  |  ');
  }

  void _hitungZakat() {
    double? harta = double.tryParse(_nominalController.text);
    double? emas = double.tryParse(_emasController.text);
    if (harta == null || harta <= 0 || emas == null || emas <= 0) {
      _snack('Isi harta dan harga emas dengan angka lebih dari 0');
      return;
    }
    if (kursHasil == null) {
      _snack('Kurs belum dimuat');
      return;
    }
    double hartaIdr = konversiUang(harta, mataUang, 'IDR', kursHasil!.kurs);
    double nisab = 85 * emas; // nisab setara 85 gram emas
    setState(() {
      if (hartaIdr < nisab) {
        hasil = 'Harta belum mencapai nisab (${formatUang(nisab, 'IDR')}). Belum wajib zakat.';
      } else {
        double zakat = harta * 0.025;
        hasil = 'Zakat maal (2,5%): ${formatUang(zakat, mataUang)}\nSetara: ${_setara(zakat)}';
      }
    });
  }

  Future<void> _konfirmasiDonasi() async {
    double? nominal = double.tryParse(_nominalController.text);
    if (nominal == null || nominal <= 0) {
      _snack('Nominal harus lebih dari 0');
      return;
    }
    if (kursHasil == null) {
      _snack('Kurs belum dimuat');
      return;
    }
    double amountIdr = konversiUang(nominal, mataUang, 'IDR', kursHasil!.kurs);
    String alias = _aliasController.text.trim().isEmpty
        ? 'Hamba Allah'
        : _aliasController.text.trim();

    final blok = await buatBlokDonasi(
      alias: alias,
      campaign: kampanye,
      amount: nominal,
      currency: mataUang,
      amountIdr: amountIdr,
      rate: amountIdr / nominal,
    );
    if (!mounted) return;
    setState(() {
      hasil = 'Donasi tercatat di blok #${blok.idx}\n'
          'Setara: ${formatUang(amountIdr, 'IDR')}\n'
          'Hash: ${blok.hash.substring(0, 16)}...';
      _nominalController.clear();
    });
  }

  Widget _modeButton(String nama) {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          mode = nama;
          hasil = '';
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: mode == nama ? Colors.green : Colors.grey,
        foregroundColor: Colors.white,
      ),
      child: Text(nama),
    );
  }

  Widget _inputField(TextEditingController controller, String hint, {bool angka = true}) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        keyboardType: angka ? TextInputType.number : TextInputType.text,
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
      appBar: AppBar(title: Text('Zakat & Donasi')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [_modeButton('Zakat'), SizedBox(width: 8), _modeButton('Donasi')],
            ),
            SizedBox(height: 12),
            Text('Mata uang'),
            DropdownButton<String>(
              value: mataUang,
              isExpanded: true,
              items: daftarMataUang
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) {
                setState(() {
                  mataUang = v!;
                });
              },
            ),
            _inputField(_nominalController, mode == 'Zakat' ? 'Total harta ($mataUang)' : 'Nominal donasi ($mataUang)'),
            if (mode == 'Zakat') ...[
              _inputField(_emasController, 'Harga emas per gram (IDR), ubah sesuai hari ini'),
              SizedBox(height: 8),
              Center(child: ElevatedButton(onPressed: _hitungZakat, child: Text('Hitung Zakat'))),
            ] else ...[
              Text('Kampanye'),
              DropdownButton<String>(
                value: kampanye,
                isExpanded: true,
                items: daftarKampanye
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) {
                  setState(() {
                    kampanye = v!;
                  });
                },
              ),
              _inputField(_aliasController, 'Alias donatur', angka: false),
              SizedBox(height: 8),
              Center(
                child: ElevatedButton(
                  onPressed: _konfirmasiDonasi,
                  child: Text('Konfirmasi Donasi'),
                ),
              ),
            ],
            SizedBox(height: 16),
            if (hasil.isNotEmpty)
              Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(hasil, style: TextStyle(fontSize: 16)),
                ),
              ),
            SizedBox(height: 8),
            if (kursHasil != null)
              Text(
                'Kurs per ${kursHasil!.waktu}${kursHasil!.offline ? ' (offline)' : ''}\n'
                '1 USD = ${kursHasil!.kurs['IDR']!.toStringAsFixed(0)} IDR = ${kursHasil!.kurs['SAR']!.toStringAsFixed(2)} SAR',
                style: TextStyle(color: Colors.grey),
              ),
            SizedBox(height: 8),
            Text(
              'Donasi bersifat simulasi (dicatat, tidak ada transfer uang).',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
