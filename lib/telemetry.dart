/// Public API of the telemetry module.
///
/// DO NOT CHANGE THE SIGNATURES IN THIS FILE.
/// Downstream apps depend on it; the hidden test suite compiles against it.
library telemetry;

export 'src/telemetry_channel.dart' show Telemetry, TelemetryEvent, NativeSignal;
export 'src/event_store.dart' show EventStore;
export 'src/background_uploader.dart' show BackgroundUploader;
