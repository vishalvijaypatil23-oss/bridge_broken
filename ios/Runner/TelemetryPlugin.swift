import Flutter
import UIKit

public class TelemetryPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {

  private var sink: FlutterEventSink?
  private var timer: Timer?
  private var buffered: [[String: Any]] = []
  private let ioQueue = DispatchQueue(label: "telemetry.io")

  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = TelemetryPlugin()
    let control = FlutterMethodChannel(
      name: "app.telemetry/control", binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(instance, channel: control)
    let signals = FlutterEventChannel(
      name: "app.telemetry/signals", binaryMessenger: registrar.messenger())
    signals.setStreamHandler(instance)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "sessionUptimeMs":
      let uptime = Int(ProcessInfo.processInfo.systemUptime * 1000.0)
      result(uptime)

    case "flushNativeBuffer":
      // Fold crash dumps in off the main thread, then report the count.
      let n = buffered.count
      ioQueue.async {
        let dumps = (try? FileManager.default.contentsOfDirectory(
          atPath: NSTemporaryDirectory() + "/crashdumps")) ?? []
        for d in dumps {
          self.buffered.append(["name": "crash", "body": d])
        }
        result(self.buffered.count)
        self.buffered.removeAll()
      }
      result(n)

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  public func onListen(withArguments arguments: Any?,
                       eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    sink = events
    timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
      self.sink?(["kind": "battery", "value": Int(UIDevice.current.batteryLevel * 100)])
    }
    return nil
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    return nil
  }
}
