# Public page identities and Home confirmation

Every distinct public page has a stable emoji. Numbered catalogue pages use
`assets/screens.json`, also consumed by Hub. Tool pages are listed in
`tool/python/generate_page_identities.py`. That source generates the synchronous
Dart registry used by the shared header, including during catalogue loading.
Do not choose a title emoji from translated text or use a shared fallback.

| Page | Emoji |
| --- | --- |
| Home | 🏠 |
| Navigation Hub | 🗺️ |
| Clipboard Shelf | 📋 |
| Now Timeline | 🕒 |
| Coordinates | 📍 |
| Photo Studio | 🖼️ |
| HTTP Request Draft | 🌐 |
| UI Showcase | 🎨 |
| Composition Studio | 🎸 |
| Irony Generator | 🥐 |
| Counter Playground | 🔟 |
| MCP Integration | 👾 |

These 12 pages and all 198 numbered pages have distinct identities. Existing
deep links that open the same page share its emoji: bounding-box → Photo Studio,
composition seed → Composition Studio, clipboard workbench → Clipboard Shelf,
external/mock API → HTTP Request Draft. E2E interaction aliases share their
numbered page's identity. Examples: `🏠 ↔ 🗺️`, `🏠 → 🥐`.

Four catalogue emojis previously collided with tool pages and are reassigned:
Screen1 🌍, Screen8 🏝️, Screen110 🗓️, Screen145 🌆. Hub and page headers read the
same assignments. All other catalogue assignments remain stable.

After an intentional assignment change, run:

```sh
python3 tool/python/generate_page_identities.py
flutter test test/contracts/metadata_export_test.dart
python3 -S tool/python/metadata_contracts.py build/test-results/metadata-contracts.json
```

The thin Flutter exporter reads the actual public route table, registry, aliases,
and production title function. Python rejects missing routes, duplicate emoji
(including variation-selector-only differences), Hub/header drift, incorrect
alias targets, and incorrect rendered title identities. Pytest also checks the
generated registry against its source. Existing CI collects these checks.
Playwright exports real title text and geometry for Python validation and takes
screenshots across the five configured browser/emulation projects. Browser
emulation is not installed Android/iOS proof.

Home on Home preserves the page without confirmation or another route push.
Other pages allow one confirmation in flight; Cancel permits another attempt,
and approval keeps the guard through the outgoing route transition. Widget
regressions count dialogs and route pushes using actual callbacks, including
queued callbacks before the button is disabled. Portable browser regressions
exercise real pointer/touch taps, cancellation and Hub → Home navigation.

## Comparison with PR #175

Reviewed PR #175 at `eed7dd08e7d66dba3aa6819afebec65ab35fd7d2`.
Its generated model round trips, 592 placeholder service executions, generator
freshness check, and empty-message mutation detection are already covered by
the #176 production JSON exporter and independent Python oracle. API001/002
network services remain excluded from the placeholder producer; their special
model payload/default contracts are exported. This is not evidence of real HTTP
runtime behavior. The #175 test-file-presence-based service exclusion and
family-wide unbounded concurrency are not adopted: current exclusions are
explicit, producer concurrency is bounded, and failures retain per-case IDs.
No second Flutter smoke suite or duplicate CI job is added. The reported #175
speedup is not a measurement of this branch.
