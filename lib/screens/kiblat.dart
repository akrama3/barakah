import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../models/data.dart';
import '../models/helper.dart';

class KiblatScreen extends StatefulWidget {
  const KiblatScreen({super.key});

  @override
  State<KiblatScreen> createState() => _KiblatScreenState();
}

class _KiblatScreenState extends State<KiblatScreen> {
  double lat = defaultLat;
  double lon = defaultLon;
  bool lokasiDefault = true;
  double? heading;
  bool sensorError = false;
  bool _sudahSejajar = false;
  StreamSubscription<MagnetometerEvent>? _sub;

  @override
  void initState() {
    super.initState();
    _muatLokasi();
    _sub = magnetometerEventStream(samplingPeriod: SensorInterval.uiInterval).listen(
      (event) {
        // ponsel diletakkan datar: heading = arah bagian atas ponsel dari utara
        double h = atan2(-event.x, event.y) * 180 / pi;
        h = (h + 360) % 360;
        double kiblat = hitungKiblat(lat, lon);
        double diff = ((kiblat - h + 540) % 360) - 180;
        bool sejajar = diff.abs() <= 3;
        if (sejajar && !_sudahSejajar) {
          HapticFeedback.heavyImpact();
        }
        _sudahSejajar = sejajar;
        if (!mounted) return;
        setState(() {
          heading = h;
        });
      },
      onError: (e) {
        if (!mounted) return;
        setState(() {
          sensorError = true;
        });
      },
    );
  }

  @override
  void dispose() {
    _sub?.cancel(); // sensor dilepas saat layar ditutup
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    double kiblat = hitungKiblat(lat, lon);
    double jarak = hitungJarak(lat, lon, kabahLat, kabahLon);
    double? h = heading;
    double? diff = h == null ? null : ((kiblat - h + 540) % 360) - 180;
    bool sejajar = diff != null && diff.abs() <= 3;

    return Scaffold(
      appBar: AppBar(title: Text('Arah Kiblat')),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                lokasiDefault ? 'Lokasi default: Yogyakarta' : 'Lokasi: GPS',
                style: TextStyle(color: Colors.grey),
              ),
              SizedBox(height: 8),
              Text(
                'Kiblat: ${kiblat.toStringAsFixed(1)}° dari utara',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              Text('Jarak ke Ka\'bah: ${jarak.toStringAsFixed(0)} km'),
              SizedBox(height: 30),
              if (diff != null)
                Transform.rotate(
                  angle: diff * pi / 180,
                  child: Icon(
                    Icons.navigation,
                    size: 160,
                    color: sejajar ? Colors.green : Colors.grey,
                  ),
                )
              else
                Icon(Icons.explore_off, size: 120, color: Colors.grey),
              SizedBox(height: 20),
              if (h != null) Text('Heading: ${h.toStringAsFixed(0)}°'),
              if (sejajar)
                Text(
                  'Menghadap kiblat',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                )
              else if (diff != null)
                Text('Putar ponsel, selisih ${diff.abs().toStringAsFixed(0)}°'),
              if (sensorError || h == null)
                Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Text(
                    'Sensor magnetometer belum terbaca. Gunakan sudut kiblat di atas '
                    'dengan kompas lain.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.orange),
                  ),
                ),
              SizedBox(height: 12),
              Text(
                'Letakkan ponsel datar dan jauhkan dari benda logam/magnet. '
                'Kalibrasi dengan gerakan angka 8 bila arah meleset.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
