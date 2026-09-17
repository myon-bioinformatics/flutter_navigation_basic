# Photo Studio — import compatibility matrix

**Purpose:** inventory what Photo Studio can and cannot load, by format,
entry point, and runtime. Investigation / regression — **not** HEIC conversion.

## Files

| Path | Role |
| --- | --- |
| `test/fixtures/photo_studio/import_compat/cases.json` | Case definitions (generator-owned; **no** measured outcomes) |
| `test/fixtures/photo_studio/import_compat/evidence/*.json` | Measured outcomes per environment (never overwritten by generator) |
| `tool/python/generate_photo_import_fixtures.py` | Regenerates binaries + `cases.json` only |

```bash
# Optional regen (needs ffmpeg, heif-enc/x265 plugin, Pillow):
python3 -m pip install -r tool/python/requirements.txt
python3 tool/python/generate_photo_import_fixtures.py
```

CI does **not** run the generator. It asserts committed fixtures against
`evidence/flutter_test_ci.json`.

Outcome vocabulary: `supported` | `rejected:<reason>` | `unsupported_by_runtime` | `not_verified`.

Do **not** treat Flutter CI green as iOS Safari proof.

## Limits

| Limit | Value |
| --- | --- |
| Max raw input | 32 MiB |
| Max pixels | 40 MP |
| Document long edge | 4096 |

## Failure copy (safe)

| Condition | Reason | Key |
| --- | --- | --- |
| HEIC/HEIF detected, convert failed | `heicUnsupported` | `photoStudio.imageHeicUnsupported` |
| >32 MiB | `tooLargeBytes` | `photoStudio.imageTooLarge` |
| >40 MP | `tooManyPixels` | `photoStudio.imageTooManyPixels` |
| Other undecodable | `unsupportedFormat` | `photoStudio.imageUnsupported` |
| Undetectable | `decodeFailed` | `photoStudio.imageError` |

## Case kinds

| Kind | Meaning |
| --- | --- |
| `raster` | Intended decodable (or real synthetic bitstream) |
| `container_sniff` | ftyp-only / intentionally incomplete — **not** camera compatibility |
| `intentionally_invalid` | Truncated / empty / oversize probes |

## Measured: `flutter_test_ci` / `loader_direct_flutter_codec`

Strictly asserted by `photo_import_compat_probe_test.dart`.

| Case | Outcome |
| --- | --- |
| PNG opaque/alpha/markers | `supported` |
| JPEG baseline + progressive (markers) | `supported` |
| JPEG EXIF orientation 1–8 (64×32 markers) | `supported` **and** visual TL/size match after Flutter applies EXIF |
| WebP lossy/lossless | `supported` |
| WebP alpha (TL α∈[1,200]) | `supported` |
| GIF still | `supported` |
| AVIF ftyp-only | `rejected:undecodable` |
| HEIC ftyp-only brands | `rejected:heicConversionFailed` (sniff-only cases) |
| HEIC synthetic 64×32 (heif-enc) | `rejected:heicConversionFailed` on Flutter codec (no HEIF in this runtime) |
| Truncated / empty / >40MP (loader direct) | typed rejects |
| >32 MiB raw input (PhotoImportGate, before loader) | `rejected:tooLargeBytes` |

### EXIF visual (direct Flutter codec)

Asymmetric 64×32 markers (TL red, TR lime, BL blue, BR yellow). After decode:

| Orientation | Size | TL dominant |
| --- | --- | --- |
| 1 | 64×32 | red |
| 2 | 64×32 | lime |
| 3 | 64×32 | yellow |
| 4 | 64×32 | blue |
| 5 | 32×64 | red |
| 6 | 32×64 | blue |
| 7 | 32×64 | yellow |
| 8 | 32×64 | lime |

Native normalization is **not verified** on real iOS ImageIO or Android decoder hosts. Null-adapter unit tests validate only error mapping and do not fill native compatibility cells.

## Not verified

| Env / entry | Status |
| --- | --- |
| `ios_safari_iphone` (all) | **`not_verified`** — fill after device QA |
| `web_chrome_ci` / browser canvas | `not_verified` on VM |
| `web_file_picker` / `web_clipboard` / `native_picker` | `not_verified` |
| Real iPhone camera HEIC on Safari | **`not_verified`** (synthetic HEIC proves detection + Flutter reject only) |

## Manual iOS Safari (optional)

1. Serve Web build for the PR commit.
2. Import PNG screenshot, JPEG, default HEIC still from Photos.
3. Record success / which failure string / Retry.
4. Update `evidence/ios_safari_iphone.json` — never invent results.

## Out of scope

- Implementing HEIC→PNG on Web
- Claiming Safari support from CI

## Related tests

- `test/photo_studio/photo_import_compat_probe_test.dart` (strict evidence)
- `test/photo_studio/image_format_sniff_test.dart`
- `test/photo_studio/studio_image_loader_test.dart`
- `test/photo_studio/photo_studio_page_test.dart` (#80 regressions)
