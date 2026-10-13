import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';

class TasbihScreen extends StatefulWidget {
  const TasbihScreen({super.key});

  @override
  State<TasbihScreen> createState() => _TasbihScreenState();
}

class _TasbihScreenState extends State<TasbihScreen> {
  int count = 0;
  int target = 33;
  bool modeGoyang = true;
  DateTime _lastShake = DateTime.fromMillisecondsSinceEpoch(0);
  StreamSubscription<AccelerometerEvent>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = accelerometerEventStream().listen((e) {
      if (!modeGoyang) return;
      double mag = sqrt(e.x * e.x + e.y * e.y + e.z * e.z);
      DateTime now = DateTime.now();
      // ambang 15 m/s2 dan jeda minimal 500 ms
      if (mag > 15 && now.difference(_lastShake).inMilliseconds > 500) {
        _lastShake = now;
        _tambah();
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _tambah() {
    if (!mounted) return;
    setState(() {
      count++;
    });
    if (count == target) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Target $target tercapai, alhamdulillah')),
      );
    }
  }

  Widget _targetButton(int nilai) {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          target = nilai;
          count = 0;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: target == nilai ? Colors.green : Colors.grey,
        foregroundColor: Colors.white,
      ),
      child: Text('$nilai'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Tasbih Digital')),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Wrap(
                spacing: 8,
                children: [_targetButton(33), _targetButton(99), _targetButton(100)],
              ),
              SizedBox(height: 30),
              Text('$count', style: TextStyle(fontSize: 90, fontWeight: FontWeight.bold)),
              Text('dari $target', style: TextStyle(fontSize: 20)),
              SizedBox(height: 20),
              SwitchListTile(
                title: Text('Mode goyang'),
                subtitle: Text(modeGoyang ? 'Goyangkan ponsel untuk menghitung' : 'Tombol manual'),
                value: modeGoyang,
                onChanged: (v) {
                  setState(() {
                    modeGoyang = v;
                  });
                },
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: _tambah,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  minimumSize: Size(240, 60),
                ),
                child: Text('TAP UNTUK HITUNG'),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    count = 0;
                  });
                },
                child: Text('Reset'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
