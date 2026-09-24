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

CI runs the generator in stdlib-only `--check` mode: it verifies `cases.json`,
fixture presence/signatures, and stdlib-owned fixture drift without invoking
ffmpeg, Pillow, or heif-enc. Full regeneration remains developer/agent-only.
Flutter tests separately assert committed fixtures against
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

## Ingress capability / decision matrix

| Ingress | Acquisition boundary | MIME evidence | Shared byte pipeline | Decision for this slice |
| --- | --- | --- | --- | --- |
| Pick (Web) | browser file input | `html.File.type`; `accept` is only a chooser hint | yes | Preserve optional MIME provenance; non-empty non-image declarations reject early, bytes/decode remain authoritative for image/unknown MIME. |
| Pick (native) | `image_picker` / `XFile` | `XFile.mimeType` when supplied | yes | Same contract as Web pick; structured outcome is injectable for contract tests. |
| Paste (text) | Flutter Clipboard text + data URL/base64 parser | data URL parser validates supported image MIME when present; raw base64 has no MIME | yes | Keep parser-specific validation at acquisition boundary; do not invent MIME for raw base64. |
| Paste (binary Web) | Async Clipboard API | Clipboard item `type`; reader selects `image/*` before Blob read | yes | Keep browser-native filtering in the reader. Do not duplicate it merely to make adapters look identical; document the boundary. |
| Insert | Flutter `ContentInsertionConfiguration` | `KeyboardInsertedContent.mimeType` | yes | Non-empty non-image declaration rejects before decode; empty MIME is unknown and proceeds to byte/decode validation. |
| Drop | no current Photo Studio surface | not yet proven | not yet | Defer UI and implementation until a focused Web-standard vs Flutter spike demonstrates reach, maintenance cost and deterministic testability. |

The convergence target is the byte-oriented validation/normalize/decode pipeline, not identical acquisition APIs. MIME is optional provenance whose trust boundary depends on the acquisition mechanism. A declared `image/*` value never replaces byte-size, pixel-budget, format sniffing or decode validation.

### API choice rubric

For a future ingress or replacement adapter, prefer the least complex option that preserves desktop/mobile Web plus iOS/Android reach and deterministic tests:

1. Use a browser-standard API when the capability is Web-specific and avoids a package dependency without reducing required reach.
2. Use a Flutter API when it provides the same contract across relevant targets with less platform glue.
3. Use a platform plugin/native adapter only where browser/Flutter primitives cannot provide the required capability (for example native gallery/HEIC normalization).
4. Keep permission handling and platform availability at the acquisition boundary; converge successful bytes on the shared import gate/decoder.
5. Do not add a new UI surface (including drop) until the chosen mechanism has contract-test evidence and a clear UX/maintenance benefit.

## Reproducible Web evidence (Playwright CLI)

For Web ingress investigations, prefer reproducible Playwright CLI/test runs over hand-captured screenshots. Evidence should be tied to the PR commit and keep the machine-verifiable result separate from the human-readable image.

A useful evidence bundle contains the Playwright command/test result and exit status; browser/project and runtime/version; committed fixture/case identifier and ingress path (pick, paste, insert; future drop only after its contract is designed); assertions for the resulting Photo Studio state/failure reason; and a PNG screenshot saved by Playwright with logs/traces uploaded as CI artifacts when practical.

A screenshot is supporting evidence, not the pass condition. Validate the command/assertions independently; for retained PNG evidence also verify that the artifact exists and has a valid PNG signature (and dimensions where useful). Do not infer Safari/iOS-native compatibility from Playwright WebKit or from a mobile device descriptor: those are Web browser/emulation evidence only.

Recommended flow:

```text
fixture -> Playwright ingress action -> state assertion -> screenshot
        -> evidence validation -> CI artifact (PNG + log/trace)
```

The existing five-project Playwright matrix (Chromium, Firefox, WebKit, mobile-Chromium, mobile-WebKit) is the preferred Web coverage where the ingress operation is deterministic. Browser permission-dependent operations may instead use a deterministic local adapter/fixture contract test and record the real browser/device cell as `not_verified` rather than making CI flaky.

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
