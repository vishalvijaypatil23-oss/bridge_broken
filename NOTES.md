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
