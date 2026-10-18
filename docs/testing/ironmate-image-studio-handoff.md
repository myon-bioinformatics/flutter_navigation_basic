# Published Ironmate Image Studio → Flutter Web handoff

The Chromium Playwright test [ironmate_published_handoff.spec.ts](../../e2e/tests/ironmate_published_handoff.spec.ts) opens the actual published https://myon-bioinformatics.github.io/Ironmate/ and imports a controlled JSON scene: 96×72, opaque red/green/blue quadrants and one transparent quadrant. Ironmate renders the PNG dynamically; the source is **not** a pre-encoded fixture PNG.

The real Image Studio PNG download, Base64/data URI export and clipboard-copy UI feed Flutter Web Photo Studio (Paste photo) and Clipboard Shelf (Paste Base64 image). Both routes use the same Chromium browser context. Cases cover 1× PNG data URI and 2× raw standard padded Base64. Checks include decoded signature, size, full byte equality between original Ironmate PNG and its Base64, successful photo import and visible UI, resized 2/3 PNG signature/dimensions and solid interior RGBA/transparent samples. The resized PNG **must not be byte-equal** to the original; the geometry and pixels are checked independently to distinguish intended conversion from breakage. A JPEG MIME declaration carrying the genuine Ironmate PNG bytes must be rejected.

The test writes original/resized PNGs, Web screenshots and a JSON receipt with input and output SHA-256, source studio.js hash, imported dimensions and Flutter run SHA. A published site outage fails the test rather than falling back to a fixture. The independently maintained [photo_studio_ingress.spec.ts](../../e2e/tests/photo_studio_ingress.spec.ts) still checks the committed 64×32 PNG.

**32 MiB boundary:** The E2E requires that the PNG emitted by Ironmate is at or below 32 MiB. The Dart [base64_image_bridge_test.dart](../../test/shared/base64_image_bridge_test.dart) verifies that Flutter's clipboard cap equals PhotoImportLimits.maxInputBytes (32 MiB), and verifies exact/over boundary behavior with small representative limits and an over-limit encoded payload. This Web E2E does **not** send a 32 MiB+ clipboard value, nor claim that its physical clipboard failure path was tested.

To run with the Flutter Web server at http://localhost:8080, use:

    cd e2e
    npx playwright test --project chromium tests/ironmate_published_handoff.spec.ts

The existing Non-Dart checks workflow runs the test in its portable E2E allowlist, with only desktop Chromium exercising this clipboard-specific case. Results are evidence for **Chromium desktop Web to Chromium desktop Web**. Android physical hardware, iOS physical hardware, mobile browser clipboard permissions, HEIC/native pickers and OS clipboard policies are not tested.
