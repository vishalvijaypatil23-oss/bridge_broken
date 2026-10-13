package com.example.bridge_broken

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        TelemetryPlugin.cacheDirPath = cacheDir.absolutePath
        flutterEngine.plugins.add(TelemetryPlugin())
    }
}
