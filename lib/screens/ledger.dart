import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/data.dart';
import '../models/db_helper.dart';
import '../models/helper.dart';

class LedgerScreen extends StatefulWidget {
  const LedgerScreen({super.key});

  @override
  State<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends State<LedgerScreen> {
  List<Block> blok = [];
  String status = 'Belum diverifikasi';
  Color warnaStatus = Colors.grey;

  @override
  void initState() {
    super.initState();
    _muat();
  }

  Future<void> _muat() async {
    List<Block> data = await DbHelper.ambilBlok();
    if (!mounted) return;
    setState(() {
      blok = data;
    });
  }

  // hitung ulang semua hash dan cocokkan prev_hash
  void _verifikasi() {
    for (int i = 0; i < blok.length; i++) {
      Block b = blok[i];
      String prevSeharusnya = i == 0 ? '0' : blok[i - 1].hash;
      if (hitungHashBlok(b) != b.hash || b.prevHash != prevSeharusnya) {
        setState(() {
          status = 'Rantai tidak valid pada blok ${b.idx}';
          warnaStatus = Colors.red;
        });
        return;
      }
    }
    setState(() {
      status = 'Rantai valid (${blok.length} blok)';
      warnaStatus = Colors.green;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Ledger Donasi')),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: warnaStatus.withOpacity(0.15),
            padding: EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    status,
                    style: TextStyle(fontWeight: FontWeight.bold, color: warnaStatus),
                  ),
                ),
                ElevatedButton(onPressed: _verifikasi, child: Text('Verifikasi')),
              ],
            ),
          ),
          Expanded(
            child: blok.isEmpty
                ? Center(child: Text('Belum ada donasi tercatat'))
                : ListView.builder(
                    itemCount: blok.length,
                    itemBuilder: (context, index) {
                      // tampilkan dari blok terbaru
                      final b = blok[blok.length - 1 - index];
                      return Card(
                        child: ListTile(
                          title: Text('#${b.idx}  ${b.donorAlias} | ${b.campaign}'),
                          subtitle: Text(
                            '${b.timestamp.substring(0, 16)}\n'
                            '${formatUang(b.amount, b.currency)}\n'
                            'hash: ${b.hash.substring(0, 8)}...  prev: ${b.prevHash.length > 8 ? b.prevHash.substring(0, 8) : b.prevHash}...',
                          ),
                          isThreeLine: true,
                          trailing: Icon(Icons.copy, size: 18),
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: b.hash));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Hash blok #${b.idx} disalin')),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
