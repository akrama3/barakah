import 'package:flutter/material.dart';
import '../models/data.dart';
import '../models/helper.dart';

class ZonaWaktuScreen extends StatefulWidget {
  final Map<String, String> jadwal; // data dikirim dari Home
  const ZonaWaktuScreen({super.key, required this.jadwal});

  @override
  State<ZonaWaktuScreen> createState() => _ZonaWaktuScreenState();
}

class _ZonaWaktuScreenState extends State<ZonaWaktuScreen> {
  String zonaA = 'WIB';
  String zonaB = 'London';

  Widget _dropdown(String value, ValueChanged<String> onChanged) {
    return DropdownButton<String>(
      value: value,
      items: daftarZona
          .map((z) => DropdownMenuItem(value: z, child: Text(z)))
          .toList(),
      onChanged: (v) {
        setState(() {
          onChanged(v!);
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    DateTime now = DateTime.now();
    // asumsi: jadwal ditampilkan dalam zona perangkat
    int offsetAsal = now.timeZoneOffset.inHours;
    int offsetA = offsetZona(zonaA, now);
    int offsetB = offsetZona(zonaB, now);

    return Scaffold(
      appBar: AppBar(title: Text('Konversi Zona Waktu')),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          Text('Waktu asal: UTC+$offsetAsal (zona perangkat)'),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                children: [
                  _dropdown(zonaA, (v) => zonaA = v),
                  Text('UTC+$offsetA'),
                ],
              ),
              Column(
                children: [
                  _dropdown(zonaB, (v) => zonaB = v),
                  Text('UTC+$offsetB'),
                ],
              ),
            ],
          ),
          Divider(),
          for (String nama in namaSholat)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(nama, style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(konversiWaktu(widget.jadwal[nama]!, offsetAsal, offsetA)),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(konversiWaktu(widget.jadwal[nama]!, offsetAsal, offsetB)),
                  ),
                ],
              ),
            ),
          SizedBox(height: 12),
          Text(
            'London otomatis UTC+1 pada masa BST (akhir Maret sampai akhir Oktober).',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
