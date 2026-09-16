import UIKit
import ImageIO

/// Photo Studio HEIC/HEIF → PNG normalize helpers (orientation-baked, pixel-gated).
enum ImageNormalize {
  struct NormalizeError: Error {
    let code: String
    let message: String
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
}
