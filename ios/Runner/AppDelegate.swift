import Flutter
import UIKit
import ImageIO

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
          let png = try Self.normalizeToPng(
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
        } catch let error as NormalizeError {
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

  /// Probe ImageIO properties first, reject >maxPixels, then thumbnail with
  /// orientation transform baked in (long edge ≤ maxLongEdge).
  static func normalizeToPng(
    data: Data,
    maxPixels: Int64,
    maxLongEdge: Int
  ) throws -> Data? {
    guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
      return nil
    }
    guard
      let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil)
        as? [CFString: Any]
    else {
      return nil
    }
    let width = (props[kCGImagePropertyPixelWidth] as? NSNumber)?.intValue ?? 0
    let height = (props[kCGImagePropertyPixelHeight] as? NSNumber)?.intValue ?? 0
    guard width > 0, height > 0 else { return nil }

    let pixels = Int64(width) * Int64(height)
    if pixels > maxPixels {
      throw NormalizeError(
        code: "too_many_pixels",
        message: "Image is \(width)x\(height) (\(pixels) px) which exceeds \(maxPixels)"
      )
    }

    let options: [CFString: Any] = [
      kCGImageSourceCreateThumbnailFromImageAlways: true,
      kCGImageSourceCreateThumbnailWithTransform: true,
      kCGImageSourceThumbnailMaxPixelSize: maxLongEdge,
    ]
    guard
      let cgImage = CGImageSourceCreateThumbnailAtIndex(
        source,
        0,
        options as CFDictionary
      )
    else {
      return nil
    }
    // Thumbnail already has orientation baked via CreateThumbnailWithTransform.
    let image = UIImage(cgImage: cgImage, scale: 1.0, orientation: .up)
    return image.pngData()
  }

  struct NormalizeError: Error {
    let code: String
    let message: String
  }
}
