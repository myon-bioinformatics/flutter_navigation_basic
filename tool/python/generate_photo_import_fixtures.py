#!/usr/bin/env python3
"""Generate synthetic Photo Studio import-compat fixtures.

Stdlib + optional host tools (ffmpeg, heif-enc). Does **not** write measured
outcomes — those live in evidence/*.json and are asserted by Dart tests.

Regenerate fixtures (developer machine / agent VM with tools):

  python3 tool/python/generate_photo_import_fixtures.py

CI runs `--check`, which is stdlib-only. Full regeneration needs the optional\nhost encoders; committed fixtures + evidence remain the source of truth. No\npersonal photos, GPS, or network downloads.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import shutil
import struct
import subprocess
import tempfile
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "test" / "fixtures" / "photo_studio" / "import_compat"
CASES = OUT / "cases.json"
TMP = OUT / ".gen_tmp"

# Fixtures owned by the stdlib generator. PNG compression bytes are explicitly\n# not treated as portable: --check compares decoded scanlines plus non-IDAT\n# chunks. Encoder-backed JPEG/WebP/HEIC are structurally validated instead.
CASE_DECLARED_DETERMINISTIC_FILES = (
    "png_opaque_2x2.png",
    "png_alpha_2x2.png",
    "png_markers_64x32.png",
    "gif_still_1x1.gif",
    "avif_ftyp_only.avif",
    "heic_ftyp_heic.heic",
    "heic_ftyp_heif.heic",
    "heic_ftyp_mif1.heic",
    "heic_ftyp_msf1.heic",
    "heic_ftyp_heix.heic",
    "png_truncated.png",
    "empty.bin",
    "png_claim_10000x10000.png",
)
AUXILIARY_DETERMINISTIC_FILES = ("README_OVERSIZE.txt",)
DETERMINISTIC_FILES = CASE_DECLARED_DETERMINISTIC_FILES + AUXILIARY_DETERMINISTIC_FILES


def _require(cmd: str) -> str:
    path = shutil.which(cmd)
    if not path:
        raise SystemExit(
            f"Missing `{cmd}` on PATH. Install it to regenerate fixtures "
            f"(CI only runs this script with --check)."
        )
    return path


def _run(args: list[str]) -> None:
    subprocess.run(args, check=True, capture_output=True)


def _png_chunk(tag: bytes, data: bytes) -> bytes:
    return (
        struct.pack(">I", len(data))
        + tag
        + data
        + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)
    )


def write_png_rgba(path: Path, width: int, height: int, rgba_rows: list[bytes]) -> None:
    raw = b"".join(b"\x00" + row for row in rgba_rows)
    ihdr = struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)
    data = b"\x89PNG\r\n\x1a\n"
    data += _png_chunk(b"IHDR", ihdr)
    data += _png_chunk(b"IDAT", zlib.compress(raw, 9))
    data += _png_chunk(b"IEND", b"")
    path.write_bytes(data)


def write_png_rgb(path: Path, width: int, height: int, rgb_rows: list[bytes]) -> None:
    raw = b"".join(b"\x00" + row for row in rgb_rows)
    ihdr = struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0)
    data = b"\x89PNG\r\n\x1a\n"
    data += _png_chunk(b"IHDR", ihdr)
    data += _png_chunk(b"IDAT", zlib.compress(raw, 9))
    data += _png_chunk(b"IEND", b"")
    path.write_bytes(data)


def write_png_ihdr_only(path: Path, width: int, height: int) -> None:
    ihdr = struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0)
    data = b"\x89PNG\r\n\x1a\n"
    data += _png_chunk(b"IHDR", ihdr)
    data += _png_chunk(b"IDAT", zlib.compress(b"\x00\x00\x00\x00", 9))
    data += _png_chunk(b"IEND", b"")
    path.write_bytes(data)


def write_truncated_png(path: Path, full: Path) -> None:
    path.write_bytes(full.read_bytes()[:24])


def write_ftyp(path: Path, brand: str, compatible: list[str] | None = None) -> None:
    brands = [brand] + (compatible or [])
    body = b"ftyp" + brand.encode("ascii") + struct.pack(">I", 0)
    for b in brands:
        body += b.encode("ascii")[:4].ljust(4, b" ")
    path.write_bytes(struct.pack(">I", 4 + len(body)) + body)


def write_gif(path: Path) -> None:
    path.write_bytes(
        bytes.fromhex(
            "47494638396101000100800000000000ffffff21f90401000001002c"
            "000000000100010000020144003b"
        )
    )


def _exif_app1(orientation: int) -> bytes:
    tiff = bytearray()
    tiff += b"II"
    tiff += struct.pack("<H", 42)
    tiff += struct.pack("<I", 8)
    tiff += struct.pack("<H", 1)
    tiff += struct.pack("<HHII", 0x0112, 3, 1, orientation)
    tiff += struct.pack("<I", 0)
    payload = b"Exif\x00\x00" + bytes(tiff)
    return b"\xff\xe1" + struct.pack(">H", len(payload) + 2) + payload


def inject_jpeg_orientation(src: Path, dest: Path, orientation: int) -> None:
    jpg = src.read_bytes()
    if jpg[0:2] != b"\xff\xd8":
        raise ValueError("not jpeg")
    # After SOI, skip/replace until SOS; insert APP1 after JFIF APP0 if present.
    if jpg[2:4] == b"\xff\xe0":
        app0_len = (jpg[4] << 8) | jpg[5]
        insert_at = 2 + 2 + app0_len
    else:
        insert_at = 2
    dest.write_bytes(jpg[:insert_at] + _exif_app1(orientation) + jpg[insert_at:])


def marker_png_rgba(width: int = 64, height: int = 32) -> list[bytes]:
    """TL red, TR lime, BL blue, BR yellow — asymmetric for orientation tests."""
    rows: list[bytes] = []
    mid_x, mid_y = width // 2, height // 2
    for y in range(height):
        row = bytearray()
        for x in range(width):
            if y < mid_y and x < mid_x:
                row += bytes([255, 0, 0, 255])
            elif y < mid_y and x >= mid_x:
                row += bytes([0, 255, 0, 255])
            elif y >= mid_y and x < mid_x:
                row += bytes([0, 0, 255, 255])
            else:
                row += bytes([255, 255, 0, 255])
        rows.append(bytes(row))
    return rows


def marker_png_rgb(width: int = 64, height: int = 32) -> list[bytes]:
    rows: list[bytes] = []
    mid_x, mid_y = width // 2, height // 2
    for y in range(height):
        row = bytearray()
        for x in range(width):
            if y < mid_y and x < mid_x:
                row += bytes([255, 0, 0])
            elif y < mid_y and x >= mid_x:
                row += bytes([0, 255, 0])
            elif y >= mid_y and x < mid_x:
                row += bytes([0, 0, 255])
            else:
                row += bytes([255, 255, 0])
        rows.append(bytes(row))
    return rows


def alpha_png_rows(width: int = 8, height: int = 4) -> list[bytes]:
    """Left half alpha=128, right half opaque; RGB markers retained."""
    rows: list[bytes] = []
    mid_x, mid_y = width // 2, height // 2
    for y in range(height):
        row = bytearray()
        for x in range(width):
            a = 128 if x < mid_x else 255
            if y < mid_y and x < mid_x:
                row += bytes([255, 0, 0, a])
            elif y < mid_y and x >= mid_x:
                row += bytes([0, 255, 0, a])
            elif y >= mid_y and x < mid_x:
                row += bytes([0, 0, 255, a])
            else:
                row += bytes([255, 255, 0, a])
        rows.append(bytes(row))
    return rows


def _sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def write_deterministic_fixtures(out_dir: Path) -> None:
    """Write every fixture in DETERMINISTIC_FILES using stdlib only.

    Shared by `main()` and `_check_committed()` so the drift check compares
    against the exact same code path that produces the committed fixtures.
    """
    write_png_rgb(out_dir / "png_opaque_2x2.png", 2, 2, [
        bytes([0, 0, 0, 255, 0, 0]),
        bytes([0, 0, 255, 255, 255, 0]),
    ])
    write_png_rgba(out_dir / "png_alpha_2x2.png", 2, 2, [
        bytes([255, 0, 0, 128, 255, 0, 0, 128]),
        bytes([255, 0, 0, 128, 255, 0, 0, 128]),
    ])
    write_png_rgb(out_dir / "png_markers_64x32.png", 64, 32, marker_png_rgb(64, 32))
    write_gif(out_dir / "gif_still_1x1.gif")
    write_ftyp(out_dir / "avif_ftyp_only.avif", "avif", ["avif", "mif1"])
    for brand in ("heic", "heif", "mif1", "msf1", "heix"):
        write_ftyp(out_dir / f"heic_ftyp_{brand}.heic", brand, [brand, "mif1"])
    write_truncated_png(out_dir / "png_truncated.png", out_dir / "png_opaque_2x2.png")
    (out_dir / "empty.bin").write_bytes(b"")
    write_png_ihdr_only(out_dir / "png_claim_10000x10000.png", 10000, 10000)
    (out_dir / "README_OVERSIZE.txt").write_text(
        "Do not commit 32MiB blobs. Tests allocate maxInputBytes+1 at runtime.\n",
        encoding="utf-8",
    )


def _png_semantics(path: Path) -> tuple[tuple[tuple[bytes, bytes], ...], bytes]:
    data = path.read_bytes()
    if not data.startswith(b"\\x89PNG\\r\\n\\x1a\\n"):
        raise ValueError("bad PNG signature")
    pos = 8
    structural: list[tuple[bytes, bytes]] = []
    idat = bytearray()
    while pos + 12 <= len(data):
        length = struct.unpack(">I", data[pos:pos + 4])[0]
        tag = data[pos + 4:pos + 8]
        chunk = data[pos + 8:pos + 8 + length]
        crc_at = pos + 8 + length
        if crc_at + 4 > len(data):
            raise ValueError("truncated PNG chunk")
        expected_crc = struct.unpack(">I", data[crc_at:crc_at + 4])[0]
        actual_crc = zlib.crc32(tag + chunk) & 0xFFFFFFFF
        if expected_crc != actual_crc:
            raise ValueError(f"bad PNG CRC for {tag!r}")
        if tag == b"IDAT":
            idat.extend(chunk)
        else:
            structural.append((tag, chunk))
        pos = crc_at + 4
        if tag == b"IEND":
            break
    if not idat:
        raise ValueError("PNG has no IDAT")
    return tuple(structural), zlib.decompress(bytes(idat))


def _same_generated_fixture(name: str, committed: Path, generated: Path) -> bool:
    # Compression bytes are not a portable contract: compare decoded PNG scanlines
    # plus non-IDAT chunks instead. Other stdlib fixtures are byte deterministic.
    if name.endswith(".png") and name != "png_truncated.png":
        return _png_semantics(committed) == _png_semantics(generated)
    return committed.read_bytes() == generated.read_bytes()


def _validate_magic(path: Path, fmt: str, kind: str) -> None:
    data = path.read_bytes()
    if fmt == "empty":
        if data:
            raise ValueError("empty fixture is not empty")
    elif fmt == "jpeg" and not data.startswith(b"\\xff\\xd8"):
        raise ValueError("missing JPEG SOI")
    elif fmt == "webp" and not (len(data) >= 12 and data[:4] == b"RIFF" and data[8:12] == b"WEBP"):
        raise ValueError("missing RIFF/WEBP signature")
    elif fmt == "gif" and not data.startswith((b"GIF87a", b"GIF89a")):
        raise ValueError("missing GIF signature")
    elif fmt == "png":
        if kind == "intentionally_invalid" and path.name == "png_truncated.png":
            if not data.startswith(b"\\x89PNG\\r\\n\\x1a\\n"):
                raise ValueError("missing truncated PNG signature")
        elif not data.startswith(b"\\x89PNG\\r\\n\\x1a\\n"):
            raise ValueError("missing PNG signature")
    elif fmt in {"avif", "heic"}:
        if len(data) < 12 or data[4:8] != b"ftyp":
            raise ValueError("missing ISO-BMFF ftyp box")
        brand = data[8:12]
        allowed = {b"avif", b"avis"} if fmt == "avif" else {b"heic", b"heix", b"hevc", b"hevx", b"heim", b"heis", b"hevm", b"hevs", b"mif1", b"msf1", b"heif"}
        if brand not in allowed:
            raise ValueError(f"unexpected {fmt} major brand {brand!r}")


def _check_committed() -> int:
    """Verify committed fixture contracts without encoder dependencies."""
    try:
        committed_payload = json.loads(CASES.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        print(f"invalid cases.json: {exc}")
        return 1
    expected_payload = build_cases_payload()
    if committed_payload != expected_payload:
        print("cases.json drift: regenerate it with generate_photo_import_fixtures.py")
        return 1

    declared = {case["fixture"] for case in committed_payload["cases"] if case.get("fixture")}
    undeclared = [name for name in CASE_DECLARED_DETERMINISTIC_FILES if name not in declared]
    if undeclared:
        for name in undeclared:
            print(f"deterministic fixture absent from cases.json: {name}")
        return 1

    for case in committed_payload["cases"]:
        name = case.get("fixture")
        if not name:
            continue
        path = OUT / name
        if not path.is_file():
            print(f"missing declared fixture: {name}")
            return 1
        try:
            _validate_magic(path, case["format"], case["kind"])
        except ValueError as exc:
            print(f"fixture structure mismatch: {name}: {exc}")
            return 1

    missing_aux = [name for name in AUXILIARY_DETERMINISTIC_FILES if not (OUT / name).is_file()]
    if missing_aux:
        for name in missing_aux:
            print(f"missing auxiliary fixture: {name}")
        return 1

    with tempfile.TemporaryDirectory(prefix="photo-fixture-check-") as tmp:
        check_dir = Path(tmp)
        write_deterministic_fixtures(check_dir)
        for name in DETERMINISTIC_FILES:
            try:
                same = _same_generated_fixture(name, OUT / name, check_dir / name)
            except (OSError, ValueError, zlib.error) as exc:
                print(f"fixture validation failed: {name}: {exc}")
                return 1
            if not same:
                print(f"fixture drift: {name}")
                return 1
    print(f"photo fixture check ok: {len(declared)} declared fixtures; {len(DETERMINISTIC_FILES)} stdlib-owned fixtures")
    return 0


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="verify stdlib-owned committed fixtures without external encoders")
    args = parser.parse_args(argv)
    if args.check:
        return _check_committed()

    ffmpeg = _require("ffmpeg")
    heif_enc = _require("heif-enc")

    OUT.mkdir(parents=True, exist_ok=True)
    TMP.mkdir(parents=True, exist_ok=True)

    # --- Deterministic (stdlib-only) fixtures; see write_deterministic_fixtures ---
    write_deterministic_fixtures(OUT)
    markers = OUT / "png_markers_64x32.png"

    # --- JPEG baseline / progressive / EXIF from markers ---
    base_jpg = TMP / "markers_baseline.jpg"
    _run([
        ffmpeg, "-y", "-i", str(markers), "-q:v", "2", "-update", "1",
        str(base_jpg),
    ])
    (OUT / "jpeg_baseline_markers_64x32.jpg").write_bytes(base_jpg.read_bytes())

    prog_jpg = TMP / "markers_prog.jpg"
    try:
        from PIL import Image  # type: ignore
    except ImportError as exc:  # pragma: no cover
        raise SystemExit(
            "Pillow is required to regenerate progressive JPEG fixtures. "
            "Install via: python3 -m pip install -r tool/python/requirements.txt"
        ) from exc
    Image.open(markers).convert("RGB").save(
        prog_jpg, format="JPEG", quality=90, progressive=True
    )
    (OUT / "jpeg_progressive_markers_64x32.jpg").write_bytes(prog_jpg.read_bytes())

    for o in range(1, 9):
        inject_jpeg_orientation(
            base_jpg,
            OUT / f"jpeg_exif_orientation_{o}_markers_64x32.jpg",
            o,
        )

    # --- WebP lossy / lossless / real alpha ---
    _run([
        ffmpeg, "-y", "-i", str(markers), "-c:v", "libwebp", "-quality", "80",
        "-update", "1", str(OUT / "webp_lossy_64x32.webp"),
    ])
    _run([
        ffmpeg, "-y", "-i", str(markers), "-c:v", "libwebp", "-lossless", "1",
        "-update", "1", str(OUT / "webp_lossless_64x32.webp"),
    ])
    alpha_src = TMP / "alpha_src.png"
    write_png_rgba(alpha_src, 8, 4, alpha_png_rows(8, 4))
    _run([
        ffmpeg, "-y", "-i", str(alpha_src), "-c:v", "libwebp", "-lossless", "1",
        "-update", "1", str(OUT / "webp_alpha_8x4.webp"),
    ])

    # --- Real synthetic HEIC (decodable by libheif; Flutter may still reject) ---
    heic_out = OUT / "heic_synthetic_markers_64x32.heic"
    _run([heif_enc, "-o", str(heic_out), "-q", "40", str(markers)])

    payload = build_cases_payload()
    CASES.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")

    # Remove legacy monolithic manifest if present.
    legacy = OUT / "manifest.json"
    if legacy.exists():
        legacy.unlink()

    shutil.rmtree(TMP, ignore_errors=True)
    print(f"Wrote fixtures + {CASES.relative_to(ROOT)}")
    return 0


def build_cases_payload() -> dict:
    """Return the language-neutral fixture contract without touching encoders."""
    cases = [
        _case("png_opaque_2x2", "png", "opaque", "png_opaque_2x2.png", "raster"),
        _case("png_alpha_2x2", "png", "alpha", "png_alpha_2x2.png", "raster"),
        _case(
            "png_markers_64x32",
            "png",
            "markers",
            "png_markers_64x32.png",
            "raster",
        ),
        _case(
            "jpeg_baseline_markers_64x32",
            "jpeg",
            "baseline_markers",
            "jpeg_baseline_markers_64x32.jpg",
            "raster",
        ),
        _case(
            "jpeg_progressive_markers_64x32",
            "jpeg",
            "progressive_markers",
            "jpeg_progressive_markers_64x32.jpg",
            "raster",
        ),
        *[
            _case(
                f"jpeg_exif_orientation_{o}_markers_64x32",
                "jpeg",
                f"exif_orientation_{o}",
                f"jpeg_exif_orientation_{o}_markers_64x32.jpg",
                "raster",
                notes=f"EXIF Orientation={o}; asymmetric markers; no GPS",
            )
            for o in range(1, 9)
        ],
        _case(
            "webp_lossy_64x32",
            "webp",
            "lossy",
            "webp_lossy_64x32.webp",
            "raster",
        ),
        _case(
            "webp_lossless_64x32",
            "webp",
            "lossless",
            "webp_lossless_64x32.webp",
            "raster",
        ),
        _case(
            "webp_alpha_8x4",
            "webp",
            "alpha",
            "webp_alpha_8x4.webp",
            "raster",
            notes="Left half alpha≈128; right opaque",
        ),
        _case("gif_still_1x1", "gif", "still", "gif_still_1x1.gif", "raster"),
        _case(
            "avif_ftyp_only",
            "avif",
            "ftyp_probe",
            "avif_ftyp_only.avif",
            "container_sniff",
            notes="Intentionally invalid bitstream; sniff-only",
        ),
        *[
            _case(
                f"heic_ftyp_{b}",
                "heic",
                f"brand_{b}_ftyp_only",
                f"heic_ftyp_{b}.heic",
                "container_sniff",
                notes="Intentionally invalid; brand sniff only",
            )
            for b in ("heic", "heif", "mif1", "msf1", "heix")
        ],
        _case(
            "heic_synthetic_markers_64x32",
            "heic",
            "synthetic_hevc_still",
            "heic_synthetic_markers_64x32.heic",
            "raster",
            notes="Synthetic HEIC via heif-enc/x265; no personal data",
        ),
        _case(
            "png_truncated",
            "png",
            "truncated",
            "png_truncated.png",
            "intentionally_invalid",
        ),
        _case("empty", "empty", "empty", "empty.bin", "intentionally_invalid"),
        _case(
            "png_claim_10000x10000",
            "png",
            "oversize_pixels_claim",
            "png_claim_10000x10000.png",
            "intentionally_invalid",
        ),
        _case(
            "oversize_bytes_runtime",
            "unknown",
            "oversize_bytes",
            None,
            "intentionally_invalid",
            notes="Allocated at test runtime: maxInputBytes+1",
        ),
    ]
    
    payload = {
        "schemaVersion": 2,
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
        "entryPoints": [
            "loader_direct_flutter_codec",
            "loader_browser_canvas_adapter",
            "loader_native_normalize_adapter",
            "web_file_picker",
            "web_clipboard",
            "native_picker",
        ],
        "environments": [
            {
                "id": "flutter_test_ci",
                "runtime": "flutter_test",
                "notes": "Outcomes in evidence/flutter_test_ci.json",
            },
            {
                "id": "web_chrome_ci",
                "runtime": "chrome",
                "notes": "not claimed without Web run",
            },
            {
                "id": "ios_safari_iphone",
                "runtime": "safari",
                "notes": "Manual device QA only",
            },
            {
                "id": "android_jvm_unit",
                "runtime": "android_jvm",
                "notes": "Channel stubs / JVM",
            },
        ],
        "cases": cases,
    }
    
    return payload


def _case(
    case_id: str,
    fmt: str,
    variant: str,
    fixture: str | None,
    kind: str,
    notes: str | None = None,
) -> dict:
    return {
        "id": case_id,
        "format": fmt,
        "variant": variant,
        "fixture": fixture,
        "kind": kind,
        "notes": notes,
    }


if __name__ == "__main__":
    raise SystemExit(main())
