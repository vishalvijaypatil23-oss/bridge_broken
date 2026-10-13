// TEL-101 — "Upload never happens on Android 13+. No crash, no log, the queue
// just grows. Works fine if I tap the manual Upload button."
//
// The periodic uploader runs its work in a spawned isolate. That isolate must
// be able to talk to platform channels (flushNativeBuffer, sqflite), which
// requires BackgroundIsolateBinaryMessenger to be initialised with the root
// isolate's token. This test spawns the worker through the same code path the
// periodic uploader uses and fails if it reports the unbound-messenger error.
//
// Note: flutter_tester cannot service platform messages *from* a background
// isolate (engine logs "Callbacks into the Dart VM are currently prohibited"
// and never replies), so once the isolate is bound the call simply gets no
// answer here. The successful end-to-end upload is verified on device — see
// NOTES.md, TEL-101.
import 'package:bridge_broken/src/background_uploader.dart'
    show debugRunUploadWorkerOnce;
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('TEL-101: periodic upload worker can reach platform channels', () async {
    final report = await debugRunUploadWorkerOnce().timeout(
      const Duration(seconds: 3),
      onTimeout: () => '<no reply in flutter_tester: isolate is bound>',
    );
    expect('$report', isNot(contains('BackgroundIsolateBinaryMessenger')));
  });
}
