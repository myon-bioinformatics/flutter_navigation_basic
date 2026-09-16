import UIKit
import ImageIO

/// Photo Studio HEIC/HEIF → PNG normalize helpers (orientation-baked, pixel-gated).
enum ImageNormalize {
  struct NormalizeError: Error {
    let code: String
    let message: String
  }

  /// Pure pixel-budget gate (mirrors Android `ImageNormalizeSupport.rejectIfTooManyPixels`).
  static func rejectIfTooManyPixels(width: Int, height: Int, maxPixels: Int64) throws {
    let pixels = Int64(width) * Int64(height)
    if pixels > maxPixels {
      throw NormalizeError(
        code: "too_many_pixels",
        message: "Image is \(width)x\(height) (\(pixels) px) which exceeds \(maxPixels)"
      )
    }
  }

  /// Probe encoded dimensions without full raster.
  /// Prefers ImageIO properties; falls back to PNG IHDR so truncated
  /// oversized-claim fixtures (same bytes as Dart tests) still gate.
  static func probePixelSize(data: Data) -> (width: Int, height: Int)? {
    if let source = CGImageSourceCreateWithData(data as CFData, nil),
       let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil)
         as? [CFString: Any] {
      let width = (props[kCGImagePropertyPixelWidth] as? NSNumber)?.intValue ?? 0
      let height = (props[kCGImagePropertyPixelHeight] as? NSNumber)?.intValue ?? 0
      if width > 0, height > 0 {
        return (width, height)
      }
    }
    return pngIhdrSize(data)
  }

  /// Minimal PNG IHDR reader (8-byte signature + length/type/width/height).
  static func pngIhdrSize(_ data: Data) -> (width: Int, height: Int)? {
    let signature: [UInt8] = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]
    guard data.count >= 24 else { return nil }
    guard Array(data.prefix(8)) == signature else { return nil }
    let length = data.subdata(in: 8..<12).withUnsafeBytes {
      Int(UInt32(bigEndian: $0.load(as: UInt32.self)))
    }
    guard length == 13 else { return nil }
    guard String(data: data.subdata(in: 12..<16), encoding: .ascii) == "IHDR" else {
      return nil
    }
    let width = data.subdata(in: 16..<20).withUnsafeBytes {
      Int(UInt32(bigEndian: $0.load(as: UInt32.self)))
    }
    let height = data.subdata(in: 20..<24).withUnsafeBytes {
      Int(UInt32(bigEndian: $0.load(as: UInt32.self)))
    }
    guard width > 0, height > 0 else { return nil }
    return (width, height)
  }

  /// Probe properties first, reject >maxPixels, then thumbnail with
  /// orientation transform baked in (long edge ≤ maxLongEdge).
  static func normalizeToPng(
    data: Data,
    maxPixels: Int64,
    maxLongEdge: Int
  ) throws -> Data? {
    guard let size = probePixelSize(data: data) else {
      return nil
    }
    try rejectIfTooManyPixels(
      width: size.width,
      height: size.height,
      maxPixels: maxPixels
    )

    guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
      return nil
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
}
