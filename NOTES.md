# bridge_broken — NOTES

## Environment

```
Flutter 3.44.9 • channel stable • https://github.com/flutter/flutter.git
Framework • revision 6b182d2c75 (10 weeks ago) • 2026-08-05 10:04:07 -0700
Engine • hash b9499e4c25212536ba3a4eec4f5c1905fb3214fe (revision 5a2a6a42cc) (2 months ago) • 2026-07-31 18:31:59.000Z
Tools • Dart 3.12.2 • DevTools 2.57.0
```

## Stage 0

Gate: `flutter build apk --debug`. Time box: 90 min.
Clock started: 16:56 IST, 2026-10-13

<!-- One entry per layer:
### Layer N — <short title>  (elapsed: mm:ss)
**Error (verbatim):**
```
...
```
**File changed:** `path`
**Reason:** one line
-->

### Layer 1 — Gradle wrapper too old for AGP 9  (elapsed: 00:03)
**Error (verbatim, `flutter build apk --debug`):**
```
* Where:
Build file '/Volumes/SWTAirOne/Projects/RIB/bridge_broken/android/app/build.gradle.kts' line: 1

* What went wrong:
An exception occurred applying plugin request [id: 'com.android.application']
> Failed to apply plugin 'com.android.internal.version-check'.
   > Minimum supported Gradle version is 9.1.0. Current version is 8.4.
     Try updating the 'distributionUrl' property in /Volumes/SWTAirOne/Projects/RIB/bridge_broken/android/gradle/wrapper/gradle-wrapper.properties to 'gradle-9.1.0-bin.zip'.
```
**File changed:** `android/gradle/wrapper/gradle-wrapper.properties` — `gradle-8.4-all.zip` → `gradle-9.1.0-all.zip`
**Reason:** AGP 9.0.1 (settings.gradle.kts) requires Gradle ≥ 9.1.0; the rest of the toolchain (Kotlin 2.3.20, AGP-9 opt-out flags in gradle.properties) is AGP-9 era, so the wrapper is the outlier — bump Gradle rather than downgrade AGP.

### Layer 2 — No `namespace` (AGP 9 no longer reads manifest `package`)  (elapsed: 00:06)
**Error (verbatim, `flutter build apk --debug`):**
```
* Where:
Build file '/Volumes/SWTAirOne/Projects/RIB/bridge_broken/android/build.gradle.kts' line: 19

* What went wrong:
A problem occurred configuring project ':app'.
> Could not create an instance of type com.android.build.api.variant.impl.ApplicationVariantImpl.
   > Namespace not specified. Specify a namespace in the module's build file: /Volumes/SWTAirOne/Projects/RIB/bridge_broken/android/app/build.gradle.kts. See https://d.android.com/r/tools/upgrade-assistant/set-namespace for information about setting the namespace.

     If you've specified the package attribute in the source AndroidManifest.xml, you can use the AGP Upgrade Assistant to migrate to the namespace value in the build file. Refer to https://d.android.com/r/tools/upgrade-assistant/agp-upgrade-assistant for general information about using the AGP Upgrade Assistant.
```
**Files changed:** `android/app/build.gradle.kts` — added `namespace = "com.example.bridge_broken"`; `android/app/src/main/AndroidManifest.xml` — removed legacy `package="com.example.bridge_broken"`.
**Reason:** AGP 8+ takes the R/BuildConfig namespace only from the build file; value chosen to match the manifest's old `package` and the Kotlin package of `MainActivity.kt`/`TelemetryPlugin.kt`, so no source moves.

### Layer 3 — Java/Kotlin JVM target mismatch (11 vs 17)  (elapsed: 00:12)
**Error (verbatim, `flutter build apk --debug`):**
```
* What went wrong:
Execution failed for task ':app:compileDebugKotlin'.
> Inconsistent JVM Target Compatibility Between Java and Kotlin Tasks
    Inconsistent JVM Target Compatibility Between Java and Kotlin Tasks
      Inconsistent JVM-target compatibility detected for tasks 'compileDebugJavaWithJavac' (11) and 'compileDebugKotlin' (17).
```
**File changed:** `android/app/build.gradle.kts` — `compileOptions` source/targetCompatibility `VERSION_11` → `VERSION_17`.
**Reason:** Kotlin already targets JVM 17 (`kotlin.compilerOptions.jvmTarget`), and AGP 9 / Flutter 3.44 require 17; raise Java to match rather than drop Kotlin to 11.

Also printed on this run, **not acted on yet** (warning only, not the failure):
```
Warning: The plugin sqflite_android requires Android SDK version 36 or higher.
For more information about build configuration, see https://flutter.dev/to/review-gradle-config.
Your project is configured to compile against Android SDK 33, but the following plugin(s) require to be compiled against a higher Android SDK version:
- sqflite_android compiles against Android SDK 36
Fix this issue by compiling against the highest Android SDK version (they are backward compatible).
Add the following to /Volumes/SWTAirOne/Projects/RIB/bridge_broken/android/app/build.gradle.kts:

    android {
        compileSdk = 36
        ...
    }
```

### Layer 4 — compileSdk 33 below what dependencies require  (elapsed: 00:13)
**Error (verbatim, `flutter build apk --debug`):**
```
* What went wrong:
Execution failed for task ':app:checkDebugAarMetadata'.
> A failure occurred while executing com.android.build.gradle.internal.tasks.CheckAarMetadataWorkAction
   > 16 issues were found when checking AAR metadata:

       1.  Dependency ':sqflite_android' requires libraries and applications that
           depend on it to compile against version 36 or later of the
           Android APIs.

           :app is currently compiled against android-33.

           Recommended action: Update this project to use a newer compileSdk
           of at least 36, for example 36.

           Note that updating a library or application's compileSdk (which
           allows newer APIs to be used) can be done separately from updating
           targetSdk (which opts the app in to new runtime behavior) and
           minSdk (which determines which devices the app can be installed
           on).

       2.  Dependency 'androidx.fragment:fragment:1.7.1' requires libraries and applications that
           depend on it to compile against version 34 or later of the
           Android APIs.

           :app is currently compiled against android-33.

           Recommended action: Update this project to use a newer compileSdk
           of at least 34, for example 36.

           Note that updating a library or application's compileSdk (which
           allows newer APIs to be used) can be done separately from updating
           targetSdk (which opts the app in to new runtime behavior) and
           minSdk (which determines which devices the app can be installed
           on).


       [issues 3–16: same message for androidx.window, activity, lifecycle-*, core, core-ktx, annotation-experimental, exifinterface — all require compileSdk ≥ 34; full log in build/07_build.txt]
```
**File changed:** `android/app/build.gradle.kts` — `compileSdk = 33` → `36`; replaced the "do not bump" comment.
**Reason:** sqflite_android needs compileSdk ≥ 36 and 15 AndroidX libs need ≥ 34. The build-file comment ("Pinned… Do not bump without checking TelemetryPlugin.kt") is the misleading one: checked it — TelemetryPlugin.kt imports only `android.os.SystemClock` (API 1), and compileSdk only affects which APIs are visible at compile time, not runtime behaviour (that's targetSdk, left at `flutter.targetSdkVersion`).

### Gate passed  (elapsed: 00:14 — 16:56 → 17:10 IST)
```
Running Gradle task 'assembleDebug'...                             47.4s
✓ Built build/app/outputs/flutter-apk/app-debug.apk
```

**Left untouched on purpose (looked suspicious, no failing evidence):**
- `pubspec.yaml` `sdk: ">=3.3.0 <4.0.0"` — analyze/test/build all clean on Dart 3.12.2.
- `android/gradle.properties` `android.newDsl=false`, `android.builtInKotlin=false` — AGP 9 opt-outs that the Flutter Gradle plugin still relies on; not implicated in any error.
- `org.gradle.jvmargs=-Xmx8G …` — oversized for a laptop, but not a failure.

## Pre-ticket fix — app crashes ~1 s after launch (native signal thread)

Not one of the seven tickets, but it blocks every on-device experiment, so it is fixed first on its own branch (`fix/native-signals-main-thread`).

**Observed** (`flutter run -d ZN4222MNTZ`, moto g45 5G, Android 15 / API 35):
```
E/AndroidRuntime(30994): FATAL EXCEPTION: Thread-4
E/AndroidRuntime(30994): Process: com.example.bridge_broken, PID: 30994
E/AndroidRuntime(30994): java.lang.RuntimeException: Methods marked with @UiThread must be executed on the main thread. Current thread: Thread-4
E/AndroidRuntime(30994):        at io.flutter.embedding.engine.FlutterJNI.ensureRunningOnMainThread(FlutterJNI.java:1695)
E/AndroidRuntime(30994):        at io.flutter.embedding.engine.FlutterJNI.dispatchPlatformMessage(FlutterJNI.java:1177)
E/AndroidRuntime(30994):        at io.flutter.embedding.engine.dart.DartMessenger.send(DartMessenger.java:275)
E/AndroidRuntime(30994):        at io.flutter.embedding.engine.dart.DartExecutor$DefaultBinaryMessenger.send(DartExecutor.java:457)
E/AndroidRuntime(30994):        at io.flutter.embedding.engine.dart.DartExecutor.send(DartExecutor.java:217)
E/AndroidRuntime(30994):        at io.flutter.plugin.common.EventChannel$IncomingStreamRequestHandler$EventSinkImplementation.success(EventChannel.java:251)
E/AndroidRuntime(30994):        at com.example.bridge_broken.TelemetryPlugin.onListen$lambda$0(TelemetryPlugin.kt:61)
E/AndroidRuntime(30994):        at com.example.bridge_broken.SignalEmitter.start$lambda$0(TelemetryPlugin.kt:86)
```
**Root cause:** `SignalEmitter` calls `EventSink.success` from its own `Thread`; Flutter requires platform-channel sends on the main thread.
**Fix:** `TelemetryPlugin.kt` — post the fan-out to `Handler(Looper.getMainLooper())`. The `sinks` list / emitter lifecycle is deliberately left alone here (see TEL-103 / TEL-107).


## TEL-101 — periodic upload never happens

**Symptom.** "Upload never happens on Android 13+. No crash, no log, the queue just grows. Works fine if I tap the manual Upload button."

**Hypothesis.** The periodic uploader runs `_worker` in an `Isolate.spawn`ed isolate, and its first call (`Telemetry.flushNativeBuffer()`, then sqflite) is a platform-channel call. A spawned isolate has no binary messenger until `BackgroundIsolateBinaryMessenger.ensureInitialized(RootIsolateToken)` runs, so the call throws, and `catch (_) {}` swallows it → "no crash, no log". The manual button calls `uploadOnce()` on the root isolate, where channels work. (Nothing here is Android-13-specific; that is just where QA looked.)

**Experiment.** Temporary probe in `_worker`'s catch and in `uploadOnce` printing `Isolate.current.debugName`, `RootIsolateToken.instance != null` and the error; ran on a moto g45 5G (Android 15 / API 35):
```
adb logcat -c
adb logcat -v time flutter:I '*:S' | tee build/tel101_logcat.txt
flutter run -d ZN4222MNTZ
```

**Observed output.**
```
--------- beginning of main
10-13 17:27:33.441 I/flutter (30994): [IMPORTANT:flutter/shell/platform/android/android_context_vk_impeller.cc(62)] Using the Impeller rendering backend (Vulkan).
10-13 17:27:33.523 I/flutter (30994): [IMPORTANT:flutter/shell/platform/android/android_context_gl_impeller.cc(104)] Using the Impeller rendering backend (OpenGLES).
10-13 17:27:33.602 I/flutter (30994): The Dart VM service is listening on http://127.0.0.1:39501/0QG897jeC-M=/
10-13 17:27:34.658 I/flutter (30994): [TEL-101 probe] _worker isolate=BackgroundUploader._worker isRoot=false error=Bad state: The BackgroundIsolateBinaryMessenger.instance value is invalid until BackgroundIsolateBinaryMessenger.ensureInitialized is executed.
10-13 17:27:34.658 I/flutter (30994): [TEL-101 probe] _worker done uploaded=0
```
The line proving which isolate made the call: `_worker isolate=BackgroundUploader._worker isRoot=false` — the spawned isolate, not the root one.

Red test (`test/tel101_background_upload_test.dart`, commit "test(TEL-101): red"):
```
00:00 +4 -1: /Volumes/SWTAirOne/Projects/RIB/bridge_broken/test/tel101_background_upload_test.dart: TEL-101: periodic upload worker can reach platform channels [E]
  Expected: not contains 'BackgroundIsolateBinaryMessenger'
    Actual: 'Bad state: The BackgroundIsolateBinaryMessenger.instance value is invalid until BackgroundIsolateBinaryMessenger.ensureInitialized is executed.'
  
  package:matcher                                     expect
  package:flutter_test/src/widget_tester.dart 473:18  expect
  test/tel101_background_upload_test.dart 27:5        main.<fn>
```

After the fix — test suite:
```
00:00 +0: loading /Volumes/SWTAirOne/Projects/RIB/bridge_broken/test/telemetry_test.dart
00:00 +0: /Volumes/SWTAirOne/Projects/RIB/bridge_broken/test/widget_test.dart: placeholder
00:00 +1: /Volumes/SWTAirOne/Projects/RIB/bridge_broken/test/telemetry_test.dart: sessionUptimeMs round-trips
00:00 +2: /Volumes/SWTAirOne/Projects/RIB/bridge_broken/test/telemetry_test.dart: event maps round-trip
00:00 +3: /Volumes/SWTAirOne/Projects/RIB/bridge_broken/test/telemetry_test.dart: native signals decode
00:00 +4: /Volumes/SWTAirOne/Projects/RIB/bridge_broken/test/tel101_background_upload_test.dart: TEL-101: periodic upload worker can reach platform channels
Shell: [ERROR:flutter/runtime/dart_isolate.cc(1402)] Callbacks into the Dart VM are currently prohibited. Either there are outstanding pointers from Dart_TypedDataAcquireData that have not been released with Dart_TypedDataReleaseData, or a finalizer is running.
00:03 +5: All tests passed!
```
(`Callbacks into the Dart VM are currently prohibited` is flutter_tester being unable to answer platform messages from *any* background isolate — reproduced with a standalone probe — so in the unit test a bound isolate gets no reply. The positive path is proven on device.)

After the fix — device (`adb logcat -v time flutter:I AndroidRuntime:E '*:S'`, temporary `worker report=` probe):
```
--------- beginning of main
10-13 17:39:33.990 I/flutter (31302): [IMPORTANT:flutter/shell/platform/android/android_context_vk_impeller.cc(62)] Using the Impeller rendering backend (Vulkan).
10-13 17:39:34.026 I/flutter (31302): [IMPORTANT:flutter/shell/platform/android/android_context_gl_impeller.cc(104)] Using the Impeller rendering backend (OpenGLES).
10-13 17:39:34.170 I/flutter (31302): The Dart VM service is listening on http://127.0.0.1:43099/LZwIWtcvdYY=/
10-13 17:39:41.012 I/flutter (31302): [TEL-101 probe] worker report=0
10-13 17:40:09.219 I/flutter (31302): [TEL-101 probe] worker report=0
```
`report=0` is an int (rows uploaded), not an error string: the worker reached native and SQLite. The 7 s gap from launch matches the 4 s main-thread sleep in `flushNativeBuffer` — that is TEL-102, now reachable.

**Root cause.** `BackgroundUploader._kick` spawns a worker isolate that is never bound to the platform messenger; every plugin call in it fails with `StateError`, which the worker swallowed.

**Fix** (`lib/src/background_uploader.dart`): pass `RootIsolateToken.instance` to the worker and call `BackgroundIsolateBinaryMessenger.ensureInitialized` first; the worker now reports failures back and the spawner logs them (`[BackgroundUploader] upload failed: …`).

**Why the naive fix is wrong.**
- *Call `uploadOnce()` from the timer on the UI isolate* (it "works") — abandons the off-UI-isolate design and only hides the bug at one call site; any other code spawning a worker hits the same wall.
- *`Isolate.exit` / `Isolate.run`* — forbidden, and doesn't bind the messenger either; `Isolate.run` with a bound messenger also tripped the "Callbacks into the Dart VM are prohibited" engine error in testing.
- *Just log in the `catch`* — makes the failure visible but uploads still never happen.
