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
      guard let data = call.arguments as? FlutterStandardTypedData else {
        result(nil)
        return
      }
      // UIImage applies EXIF/HEIF orientation when materializing.
      guard let image = UIImage(data: data.data),
            let png = image.pngData() else {
        result(nil)
        return
      }
      result(FlutterStandardTypedData(bytes: png))
    }
  }
}
