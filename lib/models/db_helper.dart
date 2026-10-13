import 'package:sqflite/sqflite.dart';
import 'data.dart';

class DbHelper {
  static Database? _db;

  static Future<Database> get db async {
    if (_db != null) return _db!;
    String path = '${await getDatabasesPath()}/barakah.db';
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (database, version) async {
        await database.execute(
          'CREATE TABLE users (username TEXT PRIMARY KEY, nama TEXT NOT NULL, '
          'salt TEXT NOT NULL, password_hash TEXT NOT NULL)',
        );
        await database.execute(
          'CREATE TABLE ledger (idx INTEGER PRIMARY KEY, timestamp TEXT NOT NULL, '
          'donor_alias TEXT NOT NULL, campaign TEXT NOT NULL, amount REAL NOT NULL, '
          'currency TEXT NOT NULL, amount_idr REAL NOT NULL, rate_used REAL NOT NULL, '
          'prev_hash TEXT NOT NULL, hash TEXT NOT NULL UNIQUE)',
        );
        await database.execute(
          'CREATE TABLE saran (id INTEGER PRIMARY KEY AUTOINCREMENT, '
          'username TEXT NOT NULL, saran TEXT NOT NULL, kesan TEXT NOT NULL, '
          'waktu TEXT NOT NULL)',
        );
      },
    );
    return _db!;
  }

  // ----- users -----
  static Future<void> simpanUser(
    String username,
    String nama,
    String salt,
    String passwordHash,
  ) async {
    final database = await db;
    await database.insert('users', {
      'username': username,
      'nama': nama,
      'salt': salt,
      'password_hash': passwordHash,
    });
  }

  static Future<Map<String, dynamic>?> ambilUser(String username) async {
    final database = await db;
    final hasil = await database.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    );
    if (hasil.isEmpty) return null;
    return hasil.first;
  }

  // ----- ledger -----
  static Future<List<Block>> ambilBlok() async {
    final database = await db;
    final hasil = await database.query('ledger', orderBy: 'idx ASC');
    return hasil.map((m) => Block.fromMap(m)).toList();
  }

  static Future<void> simpanBlok(Block b) async {
    final database = await db;
    await database.insert('ledger', b.toMap());
  }

  // ----- saran & kesan -----
  static Future<void> simpanSaran(String username, String saran, String kesan) async {
    final database = await db;
    await database.insert('saran', {
      'username': username,
      'saran': saran,
      'kesan': kesan,
      'waktu': DateTime.now().toString().substring(0, 16),
    });
  }

  static Future<List<Map<String, dynamic>>> ambilSaran(String username) async {
    final database = await db;
    return await database.query(
      'saran',
      where: 'username = ?',
      whereArgs: [username],
      orderBy: 'id DESC',
    );
  }
}
