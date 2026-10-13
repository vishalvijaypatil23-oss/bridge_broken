import 'dart:async';
import 'dart:isolate';

import 'event_store.dart';
import 'telemetry_channel.dart';

/// Uploads pending events off the UI isolate.
///
/// The manual "Upload now" button in the Telemetry page calls [uploadOnce]
/// directly. The periodic uploader runs [_worker] in a spawned isolate.
class BackgroundUploader {
  BackgroundUploader._();
  static final BackgroundUploader instance = BackgroundUploader._();

  Isolate? _isolate;
  Timer? _timer;

  Future<void> start({Duration every = const Duration(seconds: 30)}) async {
    _timer?.cancel();
    _timer = Timer.periodic(every, (_) => _kick());
    await _kick();
  }

  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
  }

  Future<void> _kick() async {
    final rp = ReceivePort();
    _isolate = await Isolate.spawn(_worker, rp.sendPort);
    rp.listen((msg) {
      // Worker reports how many it uploaded. Nothing to do with it yet.
      rp.close();
    });
  }

  /// Runs in the spawned isolate.
  static Future<void> _worker(SendPort reply) async {
    var uploaded = 0;
    try {
      // Pull anything native still has buffered before we read the table,
      // otherwise we upload a stale window.
      await Telemetry.flushNativeBuffer();

      final rows = await EventStore.instance.pending();
      // ... network POST elided for the take-home; assume it succeeds ...
      await EventStore.instance
          .markUploaded(rows.map((r) => r['id']! as int).toList());
      uploaded = rows.length;
    } catch (_) {
      // Uploading is best effort; never let it take the app down.
    }
    reply.send(uploaded);
  }

  /// Same work, on the calling isolate. Used by the manual button.
  static Future<int> uploadOnce() async {
    await Telemetry.flushNativeBuffer();
    final rows = await EventStore.instance.pending();
    await EventStore.instance
        .markUploaded(rows.map((r) => r['id']! as int).toList());
    return rows.length;
  }
}
