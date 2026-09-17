#!/usr/bin/env python3
"""Generate synthetic Photo Studio import-compat fixtures (stdlib only).

Regenerate:
  python3 tool/python/generate_photo_import_fixtures.py

Outputs under test/fixtures/photo_studio/import_compat/ plus a machine-readable
manifest skeleton (outcomes filled by Dart probe tests / manual QA).
No personal photos, GPS, or network downloads.
"""

from __future__ import annotations

import json
import struct
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "test" / "fixtures" / "photo_studio" / "import_compat"
MANIFEST = OUT / "manifest.json"

# Tiny precomputed WebP payloads (2×2), stdlib cannot encode WebP.
# RIFF/WEBP VP8 lossy and VP8L lossless with alpha — synthetic, no EXIF/GPS.
WEBP_LOSSY = bytes.fromhex(
    "52494646"  # RIFF
    "24000000"  # size
    "57454250"  # WEBP
    "56503820"  # VP8
    "18000000"
    "3001009d012a02000200003e8195280300"
    "000000000000000000000000"
)
# Minimal VP8L 1×1 green pixel (known-good tiny lossless).
WEBP_LOSSLESS = bytes.fromhex(
    "524946461a000000574542505650384c0d0000002f00"
    "0000100710018fe807"
)
# VP8L with alpha is still lossless container; reuse lossless for probe label.
WEBP_ALPHA = WEBP_LOSSLESS


def _png_chunk(tag: bytes, data: bytes) -> bytes:
    return (
        struct.pack(">I", len(data))
        + tag
        + data
        + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)
    )


def write_png(
    path: Path,
    width: int,
    height: int,
    *,
    rgba: bool,
    pixels: bytes | None = None,
) -> None:
    color_type = 6 if rgba else 2
    bpp = 4 if rgba else 3
    if pixels is None:
        row = bytes([0] + ([0, 0, 0, 255] if rgba else [0, 0, 0]) * width)
        pixels = row * height
    raw = b""
    stride = 1 + width * bpp
    for y in range(height):
        raw += pixels[y * stride : (y + 1) * stride]
    ihdr = struct.pack(">IIBBBBB", width, height, 8, color_type, 0, 0, 0)
    data = b"\x89PNG\r\n\x1a\n"
    data += _png_chunk(b"IHDR", ihdr)
    data += _png_chunk(b"IDAT", zlib.compress(raw, 9))
    data += _png_chunk(b"IEND", b"")
    path.write_bytes(data)


def write_png_ihdr_only(path: Path, width: int, height: int) -> None:
    """IHDR claims size without a full raster (pixel-budget probe)."""
    ihdr = struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0)
    data = b"\x89PNG\r\n\x1a\n"
    data += _png_chunk(b"IHDR", ihdr)
    # Tiny IDAT so some parsers accept the file object; Flutter still reads IHDR.
    data += _png_chunk(b"IDAT", zlib.compress(b"\x00\x00\x00\x00", 9))
    data += _png_chunk(b"IEND", b"")
    path.write_bytes(data)


def write_truncated_png(path: Path) -> None:
    write_png(OUT / "_tmp_full.png", 2, 2, rgba=False)
    full = (OUT / "_tmp_full.png").read_bytes()
    (OUT / "_tmp_full.png").unlink()
    path.write_bytes(full[:24])  # signature + partial IHDR


# 1×1 baseline grayscale JPEG (synthetic; no EXIF/GPS). Validated via `file`.
_TINY_JPEG_BASELINE = bytes(
    [
        0xFF,
        0xD8,
        0xFF,
        0xE0,
        0x00,
        0x10,
        0x4A,
        0x46,
        0x49,
        0x46,
        0x00,
        0x01,
        0x01,
        0x00,
        0x00,
        0x01,
        0x00,
        0x01,
        0x00,
        0x00,
        0xFF,
        0xDB,
        0x00,
        0x43,
        0x00,
        0x08,
        0x06,
        0x06,
        0x07,
        0x06,
        0x05,
        0x08,
        0x07,
        0x07,
        0x07,
        0x09,
        0x09,
        0x08,
        0x0A,
        0x0C,
        0x14,
        0x0D,
        0x0C,
        0x0B,
        0x0B,
        0x0C,
        0x19,
        0x12,
        0x13,
        0x0F,
        0x14,
        0x1D,
        0x1A,
        0x1F,
        0x1E,
        0x1D,
        0x1A,
        0x1C,
        0x1C,
        0x20,
        0x24,
        0x2E,
        0x27,
        0x20,
        0x22,
        0x2C,
        0x23,
        0x1C,
        0x1C,
        0x28,
        0x37,
        0x29,
        0x2C,
        0x30,
        0x31,
        0x34,
        0x34,
        0x34,
        0x1F,
        0x27,
        0x39,
        0x3D,
        0x38,
        0x32,
        0x3C,
        0x2E,
        0x33,
        0x34,
        0x32,
        0xFF,
        0xC0,
        0x00,
        0x0B,
        0x08,
        0x00,
        0x01,
        0x00,
        0x01,
        0x01,
        0x01,
        0x11,
        0x00,
        0xFF,
        0xC4,
        0x00,
        0x1F,
        0x00,
        0x00,
        0x01,
        0x05,
        0x01,
        0x01,
        0x01,
        0x01,
        0x01,
        0x01,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x01,
        0x02,
        0x03,
        0x04,
        0x05,
        0x06,
        0x07,
        0x08,
        0x09,
        0x0A,
        0x0B,
        0xFF,
        0xC4,
        0x00,
        0xB5,
        0x10,
        0x00,
        0x02,
        0x01,
        0x03,
        0x03,
        0x02,
        0x04,
        0x03,
        0x05,
        0x05,
        0x04,
        0x04,
        0x00,
        0x00,
        0x01,
        0x7D,
        0x01,
        0x02,
        0x03,
        0x00,
        0x04,
        0x11,
        0x05,
        0x12,
        0x21,
        0x31,
        0x41,
        0x06,
        0x13,
        0x51,
        0x61,
        0x07,
        0x22,
        0x71,
        0x14,
        0x32,
        0x81,
        0x91,
        0xA1,
        0x08,
        0x23,
        0x42,
        0xB1,
        0xC1,
        0x15,
        0x52,
        0xD1,
        0xF0,
        0x24,
        0x33,
        0x62,
        0x72,
        0x82,
        0x09,
        0x0A,
        0x16,
        0x17,
        0x18,
        0x19,
        0x1A,
        0x25,
        0x26,
        0x27,
        0x28,
        0x29,
        0x2A,
        0x34,
        0x35,
        0x36,
        0x37,
        0x38,
        0x39,
        0x3A,
        0x43,
        0x44,
        0x45,
        0x46,
        0x47,
        0x48,
        0x49,
        0x4A,
        0x53,
        0x54,
        0x55,
        0x56,
        0x57,
        0x58,
        0x59,
        0x5A,
        0x63,
        0x64,
        0x65,
        0x66,
        0x67,
        0x68,
        0x69,
        0x6A,
        0x73,
        0x74,
        0x75,
        0x76,
        0x77,
        0x78,
        0x79,
        0x7A,
        0x83,
        0x84,
        0x85,
        0x86,
        0x87,
        0x88,
        0x89,
        0x8A,
        0x92,
        0x93,
        0x94,
        0x95,
        0x96,
        0x97,
        0x98,
        0x99,
        0x9A,
        0xA2,
        0xA3,
        0xA4,
        0xA5,
        0xA6,
        0xA7,
        0xA8,
        0xA9,
        0xAA,
        0xB2,
        0xB3,
        0xB4,
        0xB5,
        0xB6,
        0xB7,
        0xB8,
        0xB9,
        0xBA,
        0xC2,
        0xC3,
        0xC4,
        0xC5,
        0xC6,
        0xC7,
        0xC8,
        0xC9,
        0xCA,
        0xD2,
        0xD3,
        0xD4,
        0xD5,
        0xD6,
        0xD7,
        0xD8,
        0xD9,
        0xDA,
        0xE1,
        0xE2,
        0xE3,
        0xE4,
        0xE5,
        0xE6,
        0xE7,
        0xE8,
        0xE9,
        0xEA,
        0xF1,
        0xF2,
        0xF3,
        0xF4,
        0xF5,
        0xF6,
        0xF7,
        0xF8,
        0xF9,
        0xFA,
        0xFF,
        0xDA,
        0x00,
        0x08,
        0x01,
        0x01,
        0x00,
        0x00,
        0x3F,
        0x00,
        0x7F,
        0x46,
        0xDC,
        0xE3,
        0x4F,
        0xFF,
        0xD9,
    ]
)

# Progressive probe: SOF0→SOF2 flip. May be rejected by strict decoders; that is OK.
_TINY_JPEG_PROGRESSIVE = (
    _TINY_JPEG_BASELINE[: _TINY_JPEG_BASELINE.find(b"\xff\xc0")]
    + b"\xff\xc2"
    + _TINY_JPEG_BASELINE[_TINY_JPEG_BASELINE.find(b"\xff\xc0") + 2 :]
)


def _exif_app1(orientation: int) -> bytes:
    """Minimal Exif APP1 with Orientation tag only (no GPS)."""
    # TIFF little-endian IFD0 with one entry: Orientation (0x0112) SHORT = orientation
    tiff = bytearray()
    tiff += b"II"  # little endian
    tiff += struct.pack("<H", 42)
    tiff += struct.pack("<I", 8)  # offset to IFD0
    tiff += struct.pack("<H", 1)  # 1 entry
    # entry: tag, type=3 (SHORT), count=1, value in next 4 bytes
    tiff += struct.pack("<HHII", 0x0112, 3, 1, orientation)
    tiff += struct.pack("<I", 0)  # next IFD
    payload = b"Exif\x00\x00" + bytes(tiff)
    return b"\xff\xe1" + struct.pack(">H", len(payload) + 2) + payload


def write_jpeg_with_orientation(path: Path, orientation: int) -> None:
    # Insert APP1 after SOI / JFIF APP0.
    jpg = _TINY_JPEG_BASELINE
    # After SOI (2) + APP0 (size at bytes 4..5)
    app0_len = (jpg[4] << 8) | jpg[5]
    insert_at = 2 + 2 + app0_len
    path.write_bytes(jpg[:insert_at] + _exif_app1(orientation) + jpg[insert_at:])


def write_ftyp(path: Path, brand: str, compatible: list[str] | None = None) -> None:
    brands = [brand] + (compatible or [])
    # size(4) + 'ftyp' + major(4) + minor(4) + compatible brands
    body = b"ftyp" + brand.encode("ascii") + struct.pack(">I", 0)
    for b in brands:
        body += b.encode("ascii")[:4].ljust(4, b" ")
    size = 4 + len(body)
    path.write_bytes(struct.pack(">I", size) + body)


def write_gif(path: Path) -> None:
    # 1×1 GIF89a, single black pixel, no animation.
    path.write_bytes(
        bytes.fromhex(
            "47494638396101000100800000000000ffffff21f90401000001002c"
            "000000000100010000020144003b"
        )
    )


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)

    # PNG
    write_png(OUT / "png_opaque_2x2.png", 2, 2, rgba=False)
    # Transparent: red with alpha 128
    row = bytes([0, 255, 0, 0, 128, 255, 0, 0, 128])
    write_png(OUT / "png_alpha_2x2.png", 2, 2, rgba=True, pixels=row * 2)

    # JPEG baseline / progressive / EXIF orientations
    (OUT / "jpeg_baseline_1x1.jpg").write_bytes(_TINY_JPEG_BASELINE)
    (OUT / "jpeg_progressive_1x1.jpg").write_bytes(_TINY_JPEG_PROGRESSIVE)
    for o in range(1, 9):
        write_jpeg_with_orientation(OUT / f"jpeg_exif_orientation_{o}.jpg", o)

    # WebP
    (OUT / "webp_lossy_2x2.webp").write_bytes(WEBP_LOSSY)
    (OUT / "webp_lossless_1x1.webp").write_bytes(WEBP_LOSSLESS)
    (OUT / "webp_alpha_1x1.webp").write_bytes(WEBP_ALPHA)

    # GIF / AVIF / HEIC brands (containers only where noted)
    write_gif(OUT / "gif_still_1x1.gif")
    write_ftyp(OUT / "avif_ftyp_only.avif", "avif", ["avif", "mif1"])
    for brand in ("heic", "heif", "mif1", "msf1", "heix"):
        write_ftyp(OUT / f"heic_ftyp_{brand}.heic", brand, [brand, "mif1"])

    # Failure probes
    write_truncated_png(OUT / "png_truncated.png")
    (OUT / "empty.bin").write_bytes(b"")
    write_png_ihdr_only(OUT / "png_claim_10000x10000.png", 10000, 10000)
    # Oversize payload is generated in-memory by tests (avoid 32MiB in git).
    (OUT / "README_OVERSIZE.txt").write_text(
        "Do not commit 32MiB blobs. Tests allocate "
        "PhotoImportLimits.maxInputBytes + 1 at runtime.\n",
        encoding="utf-8",
    )

    cases = [
        _case("png_opaque_2x2", "png", "opaque", "png_opaque_2x2.png"),
        _case("png_alpha_2x2", "png", "alpha", "png_alpha_2x2.png"),
        _case("jpeg_baseline_1x1", "jpeg", "baseline", "jpeg_baseline_1x1.jpg"),
        _case(
            "jpeg_progressive_1x1",
            "jpeg",
            "progressive",
            "jpeg_progressive_1x1.jpg",
        ),
        *[
            _case(
                f"jpeg_exif_orientation_{o}",
                "jpeg",
                f"exif_orientation_{o}",
                f"jpeg_exif_orientation_{o}.jpg",
                notes=f"EXIF Orientation={o}; no GPS",
            )
            for o in range(1, 9)
        ],
        _case("webp_lossy_2x2", "webp", "lossy", "webp_lossy_2x2.webp"),
        _case("webp_lossless_1x1", "webp", "lossless", "webp_lossless_1x1.webp"),
        _case("webp_alpha_1x1", "webp", "alpha", "webp_alpha_1x1.webp"),
        _case("gif_still_1x1", "gif", "still", "gif_still_1x1.gif"),
        _case(
            "avif_ftyp_only",
            "avif",
            "ftyp_probe",
            "avif_ftyp_only.avif",
            notes="ftyp-only probe; not a full AVIF bitstream",
        ),
        *[
            _case(
                f"heic_ftyp_{b}",
                "heic",
                f"brand_{b}",
                f"heic_ftyp_{b}.heic",
                notes="ftyp-only HEIC/HEIF brand probe; not a full bitstream",
            )
            for b in ("heic", "heif", "mif1", "msf1", "heix")
        ],
        _case("png_truncated", "png", "truncated", "png_truncated.png"),
        _case("empty", "empty", "empty", "empty.bin"),
        _case(
            "png_claim_10000x10000",
            "png",
            "oversize_pixels_claim",
            "png_claim_10000x10000.png",
            notes="IHDR claims 10000×10000 (>40MP)",
        ),
        _case(
            "oversize_bytes_runtime",
            "unknown",
            "oversize_bytes",
            None,
            notes="Allocated at test runtime: maxInputBytes+1",
        ),
    ]

    manifest = {
        "schemaVersion": 1,
        "generator": "tool/python/generate_photo_import_fixtures.py",
        "limits": {
            "maxInputBytes": 32 * 1024 * 1024,
            "maxPixels": 40_000_000,
            "maxDocumentLongEdge": 4096,
        },
        "outcomeVocabulary": [
            "supported",
            "rejected:empty",
            "rejected:tooLargeBytes",
            "rejected:tooManyPixels",
            "rejected:heicConversionFailed",
            "rejected:undecodable",
            "unsupported_by_runtime",
            "not_verified",
        ],
        "environments": [
            {
                "id": "flutter_test_ci",
                "runtime": "flutter_test",
                "os": "ci_linux_or_runner",
                "browser": None,
                "notes": "Filled by test/photo_studio/photo_import_compat_probe_test.dart",
                "commit": "see CI / docs after merge",
                "verifiedAt": None,
            },
            {
                "id": "web_chrome_ci",
                "runtime": "chrome",
                "os": "ci_linux_or_runner",
                "browser": "Chrome",
                "notes": "Optional Flutter Web; do not claim iOS Safari parity",
                "commit": None,
                "verifiedAt": None,
            },
            {
                "id": "ios_safari_iphone",
                "runtime": "safari",
                "os": "ios",
                "browser": "Safari",
                "notes": "Manual device QA only; leave not_verified without a device",
                "commit": None,
                "verifiedAt": None,
            },
            {
                "id": "android_jvm_unit",
                "runtime": "android_jvm",
                "os": "android_emulator_or_jvm",
                "browser": None,
                "notes": "Native normalize MethodChannel paths; JVM unit may stub",
                "commit": None,
                "verifiedAt": None,
            },
        ],
        "entryPoints": [
            "loader_direct_flutter_codec",
            "loader_browser_canvas_adapter",
            "loader_native_normalize_adapter",
            "web_file_picker",
            "web_clipboard",
            "native_picker",
        ],
        "cases": cases,
    }
    MANIFEST.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    print(f"Wrote {len(list(OUT.iterdir()))} files under {OUT}")


def _case(
    case_id: str,
    fmt: str,
    variant: str,
    fixture: str | None,
    notes: str | None = None,
) -> dict:
    entry = {
        ep: {
            "flutter_test_ci": "not_verified",
            "web_chrome_ci": "not_verified",
            "ios_safari_iphone": "not_verified",
            "android_jvm_unit": "not_verified",
        }
        for ep in (
            "loader_direct_flutter_codec",
            "loader_browser_canvas_adapter",
            "loader_native_normalize_adapter",
            "web_file_picker",
            "web_clipboard",
            "native_picker",
        )
    }
    return {
        "id": case_id,
        "format": fmt,
        "variant": variant,
        "fixture": fixture,
        "notes": notes,
        "entryPoints": entry,
    }


if __name__ == "__main__":
    main()
