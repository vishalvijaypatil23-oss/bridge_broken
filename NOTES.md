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
