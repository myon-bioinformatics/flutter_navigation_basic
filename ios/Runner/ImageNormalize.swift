import UIKit
import ImageIO

/// Photo Studio HEIC/HEIF → PNG normalize helpers (orientation-baked, pixel-gated).
enum ImageNormalize {
  struct NormalizeError: Error {
    let code: String
    let message: String
  }

  /// Pure pixel-budget gate (mirrors Android `ImageNormalizeSupport.rejectIfTooManyPixels`).
  /// Overflow on width×height is treated as `too_many_pixels` (no trap).
  static func rejectIfTooManyPixels(width: Int, height: Int, maxPixels: Int64) throws {
    guard width > 0, height > 0 else { return }
    let (pixels, overflow) = Int64(width).multipliedReportingOverflow(by: Int64(height))
    if overflow || pixels > maxPixels {
      let detail = overflow
        ? "Image is \(width)x\(height) (pixel count overflows Int64) which exceeds \(maxPixels)"
        : "Image is \(width)x\(height) (\(pixels) px) which exceeds \(maxPixels)"
      throw NormalizeError(code: "too_many_pixels", message: detail)
    }
  }

  /// Big-endian UInt32 via byte shifts (alignment-safe for arbitrary Data slices).
  static func readUInt32BE(_ data: Data, at offset: Int) -> UInt32? {
    guard offset >= 0, data.count >= offset + 4 else { return nil }
    let b0 = UInt32(data[data.startIndex + offset])
    let b1 = UInt32(data[data.startIndex + offset + 1])
    let b2 = UInt32(data[data.startIndex + offset + 2])
    let b3 = UInt32(data[data.startIndex + offset + 3])
    return (b0 << 24) | (b1 << 16) | (b2 << 8) | b3
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
    guard let length = readUInt32BE(data, at: 8), length == 13 else { return nil }
    guard String(data: data.subdata(in: 12..<16), encoding: .ascii) == "IHDR" else {
      return nil
    }
    guard let rawWidth = readUInt32BE(data, at: 16),
          let rawHeight = readUInt32BE(data, at: 20)
    else {
      return nil
    }
    // PNG forbids zero dimensions; reject before Int conversion edge cases.
    guard rawWidth > 0, rawHeight > 0 else { return nil }
    let width = Int(rawWidth)
    let height = Int(rawHeight)
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
