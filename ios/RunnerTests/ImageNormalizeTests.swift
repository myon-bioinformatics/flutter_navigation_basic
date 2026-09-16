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

  /// PNG whose IHDR claims 10000×10000 (100 MP) — same bytes as Dart fixtures.
  private var oversizedClaimPng: Data {
    Data([
      137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82, 0, 0, 39, 16,
      0, 0, 39, 16, 8, 2, 0, 0, 0, 53, 44, 245, 112, 0, 0, 0, 9, 73, 68, 65, 84,
      120, 156, 99, 0, 0, 0, 1, 0, 1, 94, 255, 125, 249, 0, 0, 0, 0, 73, 69, 78,
      68, 174, 66, 96, 130,
    ])
  }

  /// Crafted PNG IHDR with width=height=0xffffffff (CRC ignored; probe only).
  private var maxUInt32ClaimPng: Data {
    pngIhdrClaim(width: 0xffff_ffff, height: 0xffff_ffff)
  }

  /// Crafted PNG IHDR with zero width.
  private var zeroWidthClaimPng: Data {
    pngIhdrClaim(width: 0, height: 1)
  }

  private func pngIhdrClaim(width: UInt32, height: UInt32) -> Data {
    var bytes: [UInt8] = [
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
      0x00, 0x00, 0x00, 0x0D,
      0x49, 0x48, 0x44, 0x52,
    ]
    func appendBE(_ value: UInt32) {
      bytes.append(UInt8((value >> 24) & 0xff))
      bytes.append(UInt8((value >> 16) & 0xff))
      bytes.append(UInt8((value >> 8) & 0xff))
      bytes.append(UInt8(value & 0xff))
    }
    appendBE(width)
    appendBE(height)
    // bitDepth/colorType/compression/filter/interlace + dummy CRC + truncated body
    bytes += [8, 2, 0, 0, 0, 0, 0, 0, 0]
    return Data(bytes)
  }

  func testRejectIfTooManyPixelsThrowsBeforeDecode() {
    XCTAssertThrowsError(
      try ImageNormalize.rejectIfTooManyPixels(
        width: 10000,
        height: 10000,
        maxPixels: 40_000_000
      )
    ) { error in
      guard let normalizeError = error as? ImageNormalize.NormalizeError else {
        return XCTFail("expected NormalizeError, got \(error)")
      }
      XCTAssertEqual(normalizeError.code, "too_many_pixels")
    }
  }

  func testRejectIfTooManyPixelsAllowsUnderBudget() throws {
    try ImageNormalize.rejectIfTooManyPixels(
      width: 4000,
      height: 3000,
      maxPixels: 40_000_000
    )
  }

  func testRejectIfTooManyPixelsOverflowIsTooManyPixels() {
    // UInt32 max as Int on 64-bit; product overflows Int64.
    XCTAssertThrowsError(
      try ImageNormalize.rejectIfTooManyPixels(
        width: Int(UInt32.max),
        height: Int(UInt32.max),
        maxPixels: 40_000_000
      )
    ) { error in
      guard let normalizeError = error as? ImageNormalize.NormalizeError else {
        return XCTFail("expected NormalizeError, got \(error)")
      }
      XCTAssertEqual(normalizeError.code, "too_many_pixels")
    }
  }

  func testReadUInt32BEOnUnalignedOffset() {
    // Leading pad byte → UInt32 payload starts at odd offset 1.
    let data = Data([0xAA, 0x12, 0x34, 0x56, 0x78, 0xBB])
    XCTAssertEqual(ImageNormalize.readUInt32BE(data, at: 1), 0x1234_5678)
  }

  func testPngIhdrProbeReadsOversizedClaim() {
    let size = ImageNormalize.pngIhdrSize(oversizedClaimPng)
    XCTAssertEqual(size?.width, 10000)
    XCTAssertEqual(size?.height, 10000)
  }

  func testPngIhdrProbeReadsMaxUInt32Claim() {
    let size = ImageNormalize.pngIhdrSize(maxUInt32ClaimPng)
    XCTAssertEqual(size?.width, Int(UInt32.max))
    XCTAssertEqual(size?.height, Int(UInt32.max))
  }

  func testPngIhdrProbeRejectsZeroWidth() {
    XCTAssertNil(ImageNormalize.pngIhdrSize(zeroWidthClaimPng))
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

  func testNormalizeRejectsMaxUInt32IhdrWithoutCrash() {
    XCTAssertThrowsError(
      try ImageNormalize.normalizeToPng(
        data: maxUInt32ClaimPng,
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

  func testNormalizeZeroWidthIhdrReturnsNilWithoutCrash() throws {
    let out = try ImageNormalize.normalizeToPng(
      data: zeroWidthClaimPng,
      maxPixels: 40_000_000,
      maxLongEdge: 4096
    )
    XCTAssertNil(out)
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

  func testNormalizeEmptyDataReturnsNil() throws {
    let out = try ImageNormalize.normalizeToPng(
      data: Data(),
      maxPixels: 40_000_000,
      maxLongEdge: 4096
    )
    XCTAssertNil(out)
  }
}
