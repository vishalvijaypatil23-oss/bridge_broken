import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'telemetry_channel.dart';

/// SQLite-backed queue of pending telemetry events.
class EventStore {
  EventStore._();
  static final EventStore instance = EventStore._();

  Database? _db;

  Future<Database> _open() async {
    if (_db != null) return _db!;
    final dir = await getDatabasesPath();
    _db = await openDatabase(
      p.join(dir, 'telemetry.db'),
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE events(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            at_uptime_ms INTEGER NOT NULL,
            payload TEXT NOT NULL,
            uploaded INTEGER NOT NULL DEFAULT 0
          )
        ''');
      },
    );
    return _db!;
  }

  Future<void> append(TelemetryEvent e) async {
    final db = await _open();
    await db.insert('events', {
      'name': e.name,
      'at_uptime_ms': e.atUptimeMs,
      'payload': e.payload.toString(),
      'uploaded': 0,
    });
  }

  Future<List<Map<String, Object?>>> pending({int limit = 200}) async {
    final db = await _open();
    return db.query('events',
        where: 'uploaded = 0', orderBy: 'id ASC', limit: limit);
  }

  Future<void> markUploaded(List<int> ids) async {
    final db = await _open();
    for (final id in ids) {
      await db.update('events', {'uploaded': 1},
          where: 'id = ?', whereArgs: [id]);
    }
  }

  Future<int> pendingCount() async {
    final db = await _open();
    final r =
        await db.rawQuery('SELECT COUNT(*) AS c FROM events WHERE uploaded = 0');
    return (r.first['c'] as int?) ?? 0;
  }
}
