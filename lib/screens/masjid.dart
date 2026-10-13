import 'package:flutter/material.dart';
import '../models/data.dart';
import '../models/helper.dart';

class MasjidScreen extends StatefulWidget {
  const MasjidScreen({super.key});

  @override
  State<MasjidScreen> createState() => _MasjidScreenState();
}

class _MasjidScreenState extends State<MasjidScreen> {
  final TextEditingController _cariController = TextEditingController();
  double lat = defaultLat;
  double lon = defaultLon;
  bool lokasiDefault = true;

  @override
  void initState() {
    super.initState();
    _muatLokasi();
  }

  Future<void> _muatLokasi() async {
    final pos = await ambilLokasi();
    if (!mounted || pos == null) return;
    setState(() {
      lat = pos.latitude;
      lon = pos.longitude;
      lokasiDefault = false;
    });
  }

  double _jarak(Masjid m) => hitungJarak(lat, lon, m.lat, m.lon);

  @override
  Widget build(BuildContext context) {
    // cari berdasarkan nama, lalu urutkan dari yang terdekat
    List<Masjid> hasil = daftarMasjid
        .where((m) => m.nama.toLowerCase().contains(_cariController.text.toLowerCase()))
        .toList();
    hasil.sort((a, b) => _jarak(a).compareTo(_jarak(b)));

    return Scaffold(
      appBar: AppBar(title: Text('Masjid Terdekat')),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _cariController,
              onChanged: (value) {
                setState(() {});
              },
              decoration: InputDecoration(
                hintText: 'Cari masjid',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8.0)),
                ),
              ),
            ),
          ),
          Text(
            lokasiDefault ? 'Jarak dari lokasi default (Yogyakarta)' : 'Jarak dari lokasi GPS kamu',
            style: TextStyle(color: Colors.grey),
          ),
          Expanded(
            child: hasil.isEmpty
                ? Center(child: Text('Masjid tidak ditemukan'))
                : ListView.builder(
                    itemCount: hasil.length,
                    itemBuilder: (context, index) {
                      final m = hasil[index];
                      return ListTile(
                        leading: Icon(Icons.place, color: Colors.green),
                        title: Text(m.nama),
                        subtitle: Text(m.alamat),
                        trailing: Text('${_jarak(m).toStringAsFixed(1)} km'),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(m.nama),
                              content: Text(
                                '${m.alamat}\nJarak: ${_jarak(m).toStringAsFixed(2)} km\n'
                                'Koordinat: ${m.lat}, ${m.lon}',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text('Tutup'),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
