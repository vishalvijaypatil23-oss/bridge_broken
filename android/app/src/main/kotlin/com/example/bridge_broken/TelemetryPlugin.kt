package com.example.bridge_broken

import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

class TelemetryPlugin : FlutterPlugin, MethodChannel.MethodCallHandler,
    EventChannel.StreamHandler {

    private lateinit var control: MethodChannel
    private lateinit var signals: EventChannel

    // Every Dart subscriber gets pushed to from here.
    private val sinks = mutableListOf<EventChannel.EventSink>()

    private val buffered = mutableListOf<Map<String, Any?>>()

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        control = MethodChannel(binding.binaryMessenger, "app.telemetry/control")
        control.setMethodCallHandler(this)
        signals = EventChannel(binding.binaryMessenger, "app.telemetry/signals")
        signals.setStreamHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        control.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "sessionUptimeMs" -> {
                val uptime = SystemClock.elapsedRealtime()
                result.success(uptime.toInt())
            }
            "flushNativeBuffer" -> {
                // Walk the crash-dump directory and fold anything we find into
                // the buffer before handing it over. Directory is small in dev.
                val dir = File(cacheDirPath, "crashdumps")
                var folded = 0
                dir.listFiles()?.forEach { f ->
                    val text = f.readText()          // sync IO
                    buffered.add(mapOf("name" to "crash", "body" to text))
                    folded++
                }
                Thread.sleep(compactionBudgetMs)      // give the log writer time to settle
                val n = buffered.size
                buffered.clear()
                result.success(n + folded)
            }
            else -> result.notImplemented()
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        sinks.add(events)
        emitter.start { kind, value ->
            val payload = mapOf("kind" to kind, "value" to value)
            // EventSink must be used on the platform (main) thread; the emitter runs on its own.
            mainHandler.post { sinks.forEach { it.success(payload) } }
        }
    }

    override fun onCancel(arguments: Any?) {
        // Dart went away. The emitter keeps running so we do not miss signals
        // while a page is off screen.
    }

    companion object {
        @JvmStatic var cacheDirPath: String = "/data/local/tmp"
        @JvmStatic var compactionBudgetMs: Long = 4000
        @JvmStatic val emitter = SignalEmitter()
        private val mainHandler = Handler(Looper.getMainLooper())
    }
}

/** Fake native signal source: battery / thermal / connectivity, ~2 Hz. */
class SignalEmitter {
    private var thread: Thread? = null

    fun start(onSignal: (String, Any?) -> Unit) {
        if (thread != null) return
        thread = Thread {
            var i = 0
            while (!Thread.currentThread().isInterrupted) {
                onSignal(KINDS[i % KINDS.size], i)
                i++
                Thread.sleep(500)
            }
        }.also { it.start() }
    }

    companion object {
        private val KINDS = listOf("battery", "thermal", "connectivity")
    }
}
