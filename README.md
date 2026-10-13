# bridge_broken — telemetry module (v2.4.1)

> **This project does not build.** Its Android toolchain configuration has four
> layered version mismatches. Read `BUILD-GAUNTLET.md` at the root of the pack before you
> start: pinned toolchain, 90-minute time box, logging rules, and the unblock path.

## Setup

```bash
flutter create . --platforms=android,ios --project-name bridge_broken     # generates the scaffold; will NOT overwrite the files shipped here
flutter pub get
flutter test
flutter run --profile
```

The Android `MainActivity.kt` and iOS `TelemetryPlugin.swift` in this repo are the real
ones. If `flutter create` generated a different `MainActivity.kt` package path, move ours
to match and keep ours.

## What it does

Collects telemetry events, persists them to SQLite, and uploads them in the background.
Native code supplies the device session clock and pushes native-originated events
(battery, thermal, connectivity) over an `EventChannel`.

## Known open tickets

TEL-101 … TEL-107. See the assignment brief. Do not close them by rewriting the module.

## Public API — DO NOT CHANGE

Everything exported from `lib/telemetry.dart`.
