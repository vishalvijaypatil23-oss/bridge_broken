import 'dart:async';

import 'package:flutter/services.dart';

import 'event_store.dart';

class TelemetryEvent {
  TelemetryEvent(this.name, this.atUptimeMs, [this.payload = const {}]);

  final String name;
  final int atUptimeMs;
  final Map<String, Object?> payload;

  Map<String, Object?> toMap() =>
      {'name': name, 'atUptimeMs': atUptimeMs, 'payload': payload};

  static TelemetryEvent fromMap(Map<Object?, Object?> m) => TelemetryEvent(
        m['name']! as String,
        m['atUptimeMs']! as int,
        Map<String, Object?>.from(m['payload'] as Map? ?? const {}),
      );
}

class NativeSignal {
  NativeSignal(this.kind, this.value);
  final String kind;
  final Object? value;
}

class Telemetry {
  static const MethodChannel _control =
      MethodChannel('app.telemetry/control');
  static const EventChannel _signals = EventChannel('app.telemetry/signals');

  /// Everything we have seen this session. The Telemetry page renders the tail
  /// of this and the uploader reads the head.
  static final List<TelemetryEvent> recent = <TelemetryEvent>[];

  static Future<int> sessionUptimeMs() async {
    final int ms = await _control.invokeMethod<int>('sessionUptimeMs') ?? 0;
    return ms;
  }

  static Future<void> record(String name,
      [Map<String, Object?> payload = const {}]) async {
    final e = TelemetryEvent(name, await sessionUptimeMs(), payload);
    recent.add(e);
    await EventStore.instance.append(e);
  }

  /// Native-originated signals (battery, thermal, connectivity).
  ///
  /// Each caller gets its own subscription to the platform side.
  static Stream<NativeSignal> nativeSignals() {
    return _signals.receiveBroadcastStream().map((dynamic raw) {
      final m = raw as Map<Object?, Object?>;
      return NativeSignal(m['kind']! as String, m['value']);
    });
  }

  /// Native calls back into Dart for things it cannot answer itself
  /// (e.g. "what is the current user id?").
  ///
  /// Pages install their own handler while they are on screen.
  static void installCallbackHandler(
      Future<Object?> Function(MethodCall) handler) {
    _control.setMethodCallHandler(handler);
  }

  static void removeCallbackHandler() {
    _control.setMethodCallHandler(null);
  }

  /// Ask native to flush anything it has buffered. Used by the uploader.
  static Future<int> flushNativeBuffer() async {
    return await _control.invokeMethod<int>('flushNativeBuffer') ?? 0;
  }
}
