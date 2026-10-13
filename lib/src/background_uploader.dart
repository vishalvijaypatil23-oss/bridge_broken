import 'dart:async';
import 'dart:isolate';

import 'package:flutter/foundation.dart' show debugPrint, visibleForTesting;
import 'package:flutter/services.dart'
    show BackgroundIsolateBinaryMessenger, RootIsolateToken;

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

  Future<void> _kick() => _spawnWorker((report) {
        if (report is! int) debugPrint('[BackgroundUploader] upload failed: $report');
      });

  /// Report is the uploaded count, or the error text.
  Future<void> _spawnWorker(void Function(Object? report) onReport) async {
    final rp = ReceivePort();
    // Worker needs the root token to use platform channels.
    _isolate = await Isolate.spawn(
        _worker, <Object?>[rp.sendPort, RootIsolateToken.instance!]);
    rp.listen((msg) {
      onReport(msg);
      rp.close();
    });
  }

  /// Runs in the spawned isolate.
  static Future<void> _worker(List<Object?> args) async {
    final reply = args[0]! as SendPort;
    BackgroundIsolateBinaryMessenger.ensureInitialized(
        args[1]! as RootIsolateToken);
    Object? report = 0;
    try {
      // Pull anything native still has buffered before we read the table,
      // otherwise we upload a stale window.
      await Telemetry.flushNativeBuffer();

      final rows = await EventStore.instance.pending();
      // ... network POST elided for the take-home; assume it succeeds ...
      await EventStore.instance
          .markUploaded(rows.map((r) => r['id']! as int).toList());
      report = rows.length;
    } catch (e) {
      // Uploading is best effort; never let it take the app down.
      report = e.toString();
    }
    reply.send(report);
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

/// For tests only (not exported).
@visibleForTesting
Future<Object?> debugRunUploadWorkerOnce() {
  final done = Completer<Object?>();
  BackgroundUploader.instance._spawnWorker(done.complete);
  return done.future;
}
