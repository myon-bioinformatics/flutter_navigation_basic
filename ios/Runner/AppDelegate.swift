import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let normalizeChannelName = "com.example.flutter_application_1/image_normalize"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let messenger = engineBridge.applicationRegistrar.messenger()
    let channel = FlutterMethodChannel(
      name: normalizeChannelName,
      binaryMessenger: messenger
    )
    channel.setMethodCallHandler { call, result in
      guard call.method == "normalizeToPng" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard let args = call.arguments as? [String: Any],
            let typed = args["bytes"] as? FlutterStandardTypedData else {
        result(nil)
        return
      }
      let maxPixels = (args["maxPixels"] as? NSNumber)?.int64Value ?? (40 * 1000 * 1000)
      let maxLongEdge = (args["maxLongEdge"] as? NSNumber)?.intValue ?? 4096
      let data = typed.data

      DispatchQueue.global(qos: .userInitiated).async {
        do {
          let png = try ImageNormalize.normalizeToPng(
            data: data,
            maxPixels: maxPixels,
            maxLongEdge: maxLongEdge
          )
          DispatchQueue.main.async {
            if let png {
              result(FlutterStandardTypedData(bytes: png))
            } else {
              result(nil)
            }
          }
        } catch let error as ImageNormalize.NormalizeError {
          DispatchQueue.main.async {
            result(
              FlutterError(
                code: error.code,
                message: error.message,
                details: nil
              )
            )
          }
        } catch {
          DispatchQueue.main.async {
            result(
              FlutterError(
                code: "normalize_failed",
                message: error.localizedDescription,
                details: nil
              )
            )
          }
        }
      }
    }
  }
}
