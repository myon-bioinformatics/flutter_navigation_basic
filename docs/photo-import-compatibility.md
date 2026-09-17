# Photo Studio — import compatibility matrix

**Purpose:** inventory what Photo Studio can and cannot load, by format,
entry point, and runtime. This is an investigation / regression document —
**not** a HEIC conversion implementation.

**Synthetic fixtures only.** Regenerated with:

```bash
python3 tool/python/generate_photo_import_fixtures.py
```

Machine-readable companion: [`test/fixtures/photo_studio/import_compat/manifest.json`](../test/fixtures/photo_studio/import_compat/manifest.json).

Outcome vocabulary (per cell):

| Token | Meaning |
| --- | --- |
| `supported` | Decode path accepted bytes in that environment |
| `rejected:<reason>` | Explicit gate/rejection (`empty`, `tooLargeBytes`, `tooManyPixels`, `heicConversionFailed`, `undecodable`) |
| `unsupported_by_runtime` | Probe returned null without a typed rejection |
| `not_verified` | No reproducible result yet — **must not** be claimed as supported |

Do **not** treat Flutter CI / Chrome CI green as iOS Safari proof.

## Limits (code)

| Limit | Value | Constant |
| --- | --- | --- |
| Max raw input | 32 MiB | `PhotoImportLimits.maxInputBytes` |
| Max pixels | 40 MP | `PhotoImportLimits.maxPixels` |
| Document long edge | 4096 | `PhotoImportLimits.maxDocumentLongEdge` |

## Loader pipeline

1. **Raw byte gate** — empty / >32 MiB → reject (`PhotoImportGate.rejectRawBytes`)
2. **Direct Flutter codec probe** — `ui.ImageDescriptor.encoded` size only (`readEncodedImageSize`)
3. **If probe fails** — optional adapter:
   - Web: `browserImageDecodeAdapter` (canvas → PNG)
   - IO: `nativeImageNormalizeAdapter` (MethodChannel → PNG)
4. **Pixel gate** on probed / adapted dimensions
5. **Document normalize** — downscale + PNG encode for the editable document

## Failure copy (safe; no filenames / bytes / EXIF / GPS)

| Detected condition | `PhotoImportFailureReason` | Catalog key |
| --- | --- | --- |
| HEIC/HEIF ftyp brand, convert failed | `heicUnsupported` | `photoStudio.imageHeicUnsupported` |
| >32 MiB raw | `tooLargeBytes` | `photoStudio.imageTooLarge` |
| >40 MP | `tooManyPixels` | `photoStudio.imageTooManyPixels` |
| Other undecodable container | `unsupportedFormat` | `photoStudio.imageUnsupported` |
| Undetectable decode failure | `decodeFailed` | `photoStudio.imageError` (“Could not decode this image.”) |

## Environments

| Env id | How verified | Notes |
| --- | --- | --- |
| `flutter_test_ci` | `flutter test test/photo_studio/photo_import_compat_probe_test.dart` | Direct codec + injected native adapter |
| `web_chrome_ci` | Optional Flutter Web / Chrome | Not iOS Safari |
| `ios_safari_iphone` | Manual device QA | Leave `not_verified` without a device |
| `android_jvm_unit` | Android JVM / channel stubs | Native normalize may be stubbed |

## Matrix (human summary)

Filled from `flutter_test` probes on Linux (PR head — update SHA after push). Browser / iOS Safari remain **`not_verified`**.

### Legend for entry points

- **direct** — Flutter codec only (no adapter)
- **browser** — + browser canvas adapter (Web)
- **native** — + native normalize adapter (iOS/Android)
- **web picker / clipboard / native picker** — acquisition + same loader

### Formats (`loader_direct_flutter_codec` @ `flutter_test_ci`)

| Case | Result |
| --- | --- |
| PNG opaque / alpha | `supported` |
| JPEG baseline | `supported` |
| JPEG progressive (SOF2 probe) | `supported` |
| JPEG EXIF orientation 1–8 | `supported` (sniff reads Orientation; bake-to-upright is native-adapter concern, not asserted as visual here) |
| WebP lossy / lossless / alpha | `supported` |
| GIF still | `supported` |
| AVIF ftyp-only | `rejected:undecodable` |
| HEIC brands `heic/heif/mif1/msf1/heix` (ftyp-only) | `rejected:heicConversionFailed` → UI `heicUnsupported` |
| Truncated PNG | `rejected:undecodable` |
| Empty | `rejected:empty` → UI `decodeFailed` |
| IHDR 10000×10000 claim | `rejected:tooManyPixels` |
| >32 MiB raw | `rejected:tooLargeBytes` (page gate) |

| Entry / env | Status |
| --- | --- |
| `loader_browser_canvas_adapter` | `not_verified` on VM CI (Web-only) |
| `web_file_picker` / `web_clipboard` / `native_picker` | `not_verified` (no device automation in this PR) |
| `ios_safari_iphone` (all formats) | **`not_verified`** — leave blank until manual QA; do not infer from CI |

User report (iPhone Photos → mobile Web “Could not load photo.”) is consistent with HEIC on Web without conversion; this PR makes that failure **typed** when ftyp HEIC/HEIF is detected. Full camera HEIC bitstream + Safari canvas behavior still needs device confirmation.

## Manual iOS Safari procedure (optional)

1. Deploy or serve the Web build for the PR commit.
2. On iPhone Safari, open Photo Studio.
3. Import from Photos: PNG screenshot, JPEG, Live Photo still, default HEIC camera still.
4. Record for each: success UI / which failure string / Retry works.
5. Paste from clipboard when available; note permission denials separately (#80).
6. Update `manifest.json` cells for `ios_safari_iphone` and this doc — never invent results.

## Out of scope for this PR

- Implementing HEIC→PNG conversion on Web
- Changing EXIF orientation baking behavior beyond documenting probes
- Shipping personal photos or GPS-bearing samples

## Related tests

- `test/photo_studio/image_format_sniff_test.dart`
- `test/photo_studio/photo_import_compat_probe_test.dart`
- `test/photo_studio/studio_image_loader_test.dart`
- `test/photo_studio/photo_import_status_test.dart` (#80 status + reason keys)
- Existing `test/photo_studio/photo_studio_page_test.dart` last-request-wins / Retry regressions
