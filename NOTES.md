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
