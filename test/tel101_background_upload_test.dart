// TEL-101: worker isolate must be able to call platform channels.
// flutter_tester can't reply to background isolates, so after the fix
// the call just times out here. Real upload checked on device.
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
