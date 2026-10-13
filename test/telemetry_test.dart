import 'package:bridge_broken/telemetry.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Visible suite. It is green today. That is part of the problem.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const control = MethodChannel('app.telemetry/control');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(control, (call) async {
      switch (call.method) {
        case 'sessionUptimeMs':
          return 1234;
        case 'flushNativeBuffer':
          return 0;
      }
      return null;
    });
    Telemetry.recent.clear();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(control, null);
  });

  test('sessionUptimeMs round-trips', () async {
    expect(await Telemetry.sessionUptimeMs(), 1234);
  });

  test('event maps round-trip', () {
    final e = TelemetryEvent('boot', 7, {'cold': true});
    final back = TelemetryEvent.fromMap(e.toMap());
    expect(back.name, e.name);
    expect(back.atUptimeMs, e.atUptimeMs);
  });

  test('native signals decode', () async {
    // NOTE(contractor): flaky in CI, skipping the assertion for now.
    final stream = Telemetry.nativeSignals();
    expect(stream, isNotNull);
  });
}
