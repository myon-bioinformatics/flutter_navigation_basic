import Flutter
import UIKit
import XCTest
@testable import Runner

final class ImageNormalizeTests: XCTestCase {
  /// 1×1 PNG fixture.
  private var tinyPng: Data {
    Data([
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
      0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
      0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
      0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
      0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
      0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
    ])
  }

  /// PNG whose IHDR claims 10000×10000 (100 MP).
  private var oversizedClaimPng: Data {
    Data([
      137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82, 0, 0, 39, 16,
      0, 0, 39, 16, 8, 2, 0, 0, 0, 53, 44, 245, 112, 0, 0, 0, 9, 73, 68, 65, 84,
      120, 156, 99, 0, 0, 0, 1, 0, 1, 94, 255, 125, 249, 0, 0, 0, 0, 73, 69, 78,
      68, 174, 66, 96, 130,
    ])
  }

  func testNormalizeTinyPngReturnsPng() throws {
    let out = try ImageNormalize.normalizeToPng(
      data: tinyPng,
      maxPixels: 40_000_000,
      maxLongEdge: 4096
    )
    XCTAssertNotNil(out)
    XCTAssertEqual(out?.prefix(8), tinyPng.prefix(8))
  }

  func testNormalizeRejectsOversizedPixelClaimBeforeRaster() {
    XCTAssertThrowsError(
      try ImageNormalize.normalizeToPng(
        data: oversizedClaimPng,
        maxPixels: 40_000_000,
        maxLongEdge: 4096
      )
    ) { error in
      guard let normalizeError = error as? ImageNormalize.NormalizeError else {
        return XCTFail("expected NormalizeError, got \(error)")
      }
      XCTAssertEqual(normalizeError.code, "too_many_pixels")
    }
  }

  func testNormalizeEmptyDataReturnsNil() throws {
    let out = try ImageNormalize.normalizeToPng(
      data: Data(),
      maxPixels: 40_000_000,
      maxLongEdge: 4096
    )
    XCTAssertNil(out)
  }
}
