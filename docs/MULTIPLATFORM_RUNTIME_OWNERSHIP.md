# Multi-platform runtime ownership review

> **Status:** Accepted doctrine and decision rubric; migration candidates/sequencing remain Proposed until implemented and measured.  
> **Decided:** 2026-09, PR #89.  
> **Revisit:** after the first runtime-ownership migration slice.

## Purpose

This review asks a narrower question than “how should a Flutter app be written?”:

> For each capability in this repository, does Dart/Flutter still give the lowest total implementation, dependency, maintenance, test, and operational cost while preserving multi-platform reach?

The invariant is **multi-platform capability**, not Dart ownership. The desired product remains reachable and stable on desktop web, mobile web, Android-oriented browsers, and iPhone/iOS-oriented browsers. Native Flutter surfaces remain valid where they are the lightest or most capable owner.

This is an audit and migration rubric, not a request for a wholesale rewrite.

## Current repository signal

The repository is strongly Dart-shaped: the current tree contains thousands of `.dart` files, including a large historical API-pattern catalogue, while Python is already established under `tool/python/` for stdlib diagnostics, pytest/oracles, artifact inspection, network probing, fixture generation, and Playwright wrapping. Browser E2E already uses TypeScript/Node Playwright.

That means “Dart by default everywhere” is no longer an accurate description of the actual architecture. The project is already multi-runtime; the next step is to make ownership intentional.

## Decision rule

For every capability, score the boundary qualitatively against:

1. **User reach** — desktop web, mobile web, Android-oriented browser, iPhone/iOS-oriented browser, and native app only where required.
2. **Readability** — can a maintainer understand the implementation without framework-specific ceremony?
3. **Maintenance knowledge** — is the ecosystem/tooling broadly understood and easy to repair?
4. **Dependency weight** — runtime packages, package managers, generated files, SDK/bootstrap cost.
5. **Operational cost** — CI time, local setup, packaging, release/debug complexity.
6. **Deterministic testability** — can the behavior be proven cheaply without booting the whole Flutter application?
7. **Single source of truth** — does moving it remove duplication rather than create Dart + Python/JS copies?
8. **Platform value** — does Flutter/native integration materially help this capability?

Prefer the smallest owner that satisfies the contract. A migration that merely adds another implementation is a regression.

## Ownership classes

### Keep in Dart/Flutter

Keep code in Dart when it is part of the shipped Flutter runtime or benefits materially from Flutter:

- widgets, navigation state and application lifecycle;
- platform/plugin boundaries such as image picking, native storage and app permissions;
- UI state whose source of truth is consumed directly by widgets;
- behavior that must run offline inside the compiled application;
- native/mobile integration where a browser API cannot provide the required fidelity;
- small pure helpers already colocated with their only Dart caller when extraction would add IPC/build/runtime complexity.

Examples such as `AppNavigation`, route builders, widget controllers, and Flutter plugin integration are not Python candidates merely because Python is easier to read.

### Prefer Python for dev/test/oracle/transform work

Python may take more ownership than the old policy allowed when the capability is **not shipped as browser/client runtime** and Python makes the contract simpler:

- repository inspection and health reports;
- CI/result/artifact parsing;
- fixture generation and validation;
- filesystem/archive/JSON/text transformations;
- network diagnostics and protocol probes;
- deterministic reference/oracle calculations;
- migration/audit scripts;
- test data generation;
- browser evidence validation;
- pytest-based structural/contract tests.

Prefer stdlib first. A small, justified test dependency is acceptable when it removes substantial custom infrastructure.

Important boundary: ordinary Python does not execute directly in iOS/Android browsers. Moving browser runtime logic to Python would require a server, WASM/Pyodide-style runtime, or another bridge and is normally **heavier**, not lighter. Python should win tooling and oracle ownership without pretending to be the client UI runtime.

### Prefer browser-native HTML/CSS/JS/TS

For functionality whose contract is inherently “available from any browser”, consider web standards before adding Flutter-specific machinery:

- small static/informational surfaces;
- browser-only input/output transforms;
- URL/deep-link parsing that can be shared at the web boundary;
- clipboard/download/share/file APIs where standards provide sufficient capability;
- lightweight navigation or pages that do not need Flutter application state;
- protocol demonstrations/stubs;
- progressive enhancement and responsive layout checks.

Use TypeScript/Node where the existing ecosystem materially helps. Plain HTML/CSS/JS is valid when it is smaller.

### Deno is an evaluated option, not a quota

Deno is a good candidate for small TypeScript/JavaScript tooling when its built-in fetch, TypeScript execution, permissions, formatter/tester, or single-file distribution removes Node/npm ceremony. Do not add Deno beside Node merely for preference: it should replace complexity or own a distinct boundary.

## Initial repository classification

| Area | Current owner | Review direction | Reason |
| --- | --- | --- | --- |
| Flutter widgets / presentation | Dart/Flutter | **keep** | shipped client UI and Flutter state |
| Navigator / route builders | Dart/Flutter | **keep for now** | directly coupled to Flutter Navigator/widgets |
| Native photo/image picker/storage | Dart + plugins | **keep**, add browser evidence | platform integration is real; browser support must be measured separately |
| Pure text/JSON/file transforms in developer tooling | mixed/Dart | **Python candidate** | stdlib readability and lower bootstrap cost can win |
| Repo inspector/check orchestration | Dart-heavy | **audit for Python ownership** | developer-only; current Dart-default policy needs justification capability by capability |
| Network probe | Python stdlib | **keep Python** | already a clean non-Flutter boundary |
| Artifact/Actions parsing | Python stdlib | **keep Python** | deterministic, portable tooling |
| Formula/reference calculations | Dart-only by policy | **re-open decision** | prefer language-neutral golden fixtures; allow Python oracle only when independently derived; keep one authoritative production implementation |
| Static data embedded as Dart lists | Dart | **JSON/data candidate** | data can be language-neutral when runtime behavior does not require Dart constants |
| Mock/protocol server | Dart | **audit** | keep if it reuses product Dart contracts; otherwise Python/Deno may be lighter |
| Browser E2E | Node/TS Playwright | **keep; expand matrix** | natural browser-test boundary |
| Browser evidence validators/parity guards | Python | **expand** | cheap structural checks and browser-test-kit alignment |
| Simple web-only surfaces | Flutter Web | **HTML/CSS/JS candidate** | only for an independent URL that does not depend on Flutter routes/state; verify with the same Playwright project matrix |
| Historical API pattern catalogue | Dart | **do not mechanically migrate** | reference material; first decide whether it belongs in shipped/runtime paths at all |

## First concrete candidates

### 1. Developer toolkit ownership

The current documentation says Dart/Flutter APIs are the default for repository tooling. Replace that rule with **boundary-first ownership**:

- Flutter/app-aware inspection: Dart is natural.
- Generic filesystem/JSON/Git/Actions/archive/network work: Python stdlib is natural.
- Browser/E2E: Playwright Node/Python according to the smallest proof.
- Small TS fetch/tool scripts: Deno may be preferable when it eliminates package setup.

Do not translate working Dart tooling just to change language. Migrate only when a touched tool becomes materially simpler and tests can prove behavior parity.

### Independent oracle rule

A Python oracle is not automatically independent merely because it uses another language. The preferred order is:

1. a language-neutral JSON golden derived from an external specification or known examples;
2. an independently derived oracle using a different algorithm, invariant, or authoritative specification;
3. only then a second-language implementation when independence can be explained.

A line-for-line Dart-to-Python translation is not an oracle: it can reproduce the same bug and violates `DUPLICATE_RUNTIME_SOURCE`. Python remains valuable for readable verification, but independence matters more than language. The canonical existing example is `tool/time/generate_timezone_cases.py`: its golden records `Python stdlib zoneinfo / system IANA tzdata` as provenance, independently of the Dart implementation under test.

### Browser-native surface boundary

Plain HTML/CSS/JS/TS is a candidate only when the surface has an **independent URL**, does **not** read or duplicate Flutter route/state registries, and is exercised by the same Playwright project set used for the browser portability contract. If it needs Flutter navigation/theme/application state, keep it in Flutter or first create a language-neutral contract. This is the guard against `DUAL_ENTRYPOINT_DRIFT`.

### 2. Data vs code

Review Dart files that are primarily static data. If they do not need compile-time Dart semantics, language-neutral JSON can reduce code volume and allow Python/browser tooling to validate the same source. `assets/screens.json`, `assets/ui_showcase.json`, and `assets/display/app_text.json` already demonstrate this pattern.

Potential follow-up targets include simple catalogue-like lists such as composition/irony content. Migration requires runtime loading/error behavior and tests; do not duplicate the data in both places.

### 3. Mock/protocol infrastructure

`tool/mock_http_server.dart` is substantial and currently has a reason to remain Dart where it reuses app-side protocol behavior. Split the question:

- contracts that intentionally prove the Dart implementation stay Dart;
- generic fixture serving/protocol probes may move to Python stdlib or Deno if doing so removes custom code;
- browser-facing fixture pages can be plain HTML/JS.

The goal is not a single language; it is fewer unnecessary layers.

## JSON golden as the portable contract

Prefer a language-neutral JSON golden when the same input/output contract should be understood by Dart, Python, TypeScript/Deno, documentation tooling, or future runtimes. The JSON is the authoritative **data/behavior example**, not generated Dart/Python/Markdown text.

A useful per-case shape is:

```json
{
  "schema_version": 1,
  "id": "example_case",
  "input": {"value": "example"},
  "expected": {"value": "EXAMPLE"},
  "metadata": {"source": "spec-or-known-value"}
}
```

The exact schema is capability-specific; do not force every feature into one universal fixture. Prefer one case/file when independent provenance, review, or generation matters; prefer an array/index when many tiny cases are naturally one dataset.

### Derive files from the golden, not the reverse

**Prefer not to generate source when consuming the JSON directly is sufficient.** Runtime/test JSON consumption has fewer layers and less drift. Generate Dart/TS source only when compile-time constants, typed accessors, packaging constraints, or another concrete boundary provide enough value to justify an additional generated layer.

A development-only generator may consume JSON golden data and deterministically emit:

- Dart constants, typed fixture adapters, or generated test cases;
- Markdown documentation/examples;
- TypeScript/Deno fixtures;
- static HTML/demo data;
- other language-specific test adapters.

Python stdlib is the preferred first generator when it gives the smallest readable implementation. Deno/TypeScript is equally valid when the output belongs naturally to a browser/TS boundary. Dart generation is also valid when Dart tooling already owns the schema.

Generated code must be deliberately boring: a mechanical representation of the JSON contract, not a place where product algorithms are authored. **Do not use Python to generate arbitrary Dart business logic merely because it can.** If the generator must understand Flutter navigation/state/widget semantics, the boundary is probably wrong.

The repository already proves the **JSON-golden generation** half of this pattern: `tool/time/generate_timezone_cases.py` deterministically generates reference JSON for Dart tests and CI enforces its `--check` drift check. Its `source: Python stdlib zoneinfo / system IANA tzdata` provenance is the canonical in-repo example of an independently derived golden. The photo-import tooling also generates binaries + `cases.json` while measured evidence remains separate, but it is a local/manual regeneration tool and CI consumes committed binaries rather than enforcing the generator. **Generating Dart/Markdown/TS source from a golden is a new, not-yet-implemented extension in this repository**, not an already-proven precedent.

### Generator contract

For a JSON -> Dart/Markdown/TS generator:

1. JSON schema/golden is reviewed and language-neutral.
2. Generator is development/CI tooling only; shipped Flutter runtime does not require Python/Deno.
3. Output has a generated-file header naming generator + source golden.
4. Generation is deterministic: same JSON + generator version => byte-identical output.
5. CI provides `--check`/equivalent regeneration drift detection rather than silently rewriting committed files.
6. Generated output is never hand-edited.
7. Validation happens **before** rendering/generation; malformed/unknown schema versions fail clearly.
8. The generator contains formatting/typing projection only. Product algorithms remain in their true runtime owner.
9. If Markdown is generated, Markdown is a view of the JSON contract, not a second source of truth.
10. If generated Dart is only test data, keep it out of production runtime paths where possible.

This lets Python reduce repetitive Dart maintenance without pretending Python is the application runtime.

### JSON-to-Markdown and markdown.py

The existing `markdown` repository's JSON/Markdown transformation work is a useful design precedent: one structured representation can have human-readable Markdown projections. For this repository, prefer a tiny local renderer or a pinned reusable helper only when the documentation need is real. Do not add a cross-repository runtime dependency just to render Markdown.

A future shared contract can therefore look like:

`JSON golden -> validate -> {Dart test adapter, Python oracle input, TS/Deno fixture, Markdown documentation}`

All branches consume the same contract, while each language keeps only the code needed to execute in its own environment.

### What Python may own

Python can own more than tests without becoming product runtime:

- golden validation and schema migration;
- deterministic fixture/code/document generation;
- reference calculations independently derived from a specification;
- batch transforms and repository-wide migrations;
- generated-output drift checks;
- cross-language conformance reports.

This is particularly attractive when the equivalent Dart implementation would add ceremony or SDK coupling. The decision remains boundary-first: a small existing Dart generator should not be rewritten solely to increase Python share.

### What Deno/TypeScript may own

Prefer Deno/TypeScript when the generated/validated contract is primarily browser-facing, uses Web APIs, or benefits from TypeScript types and Deno's built-in runner/formatter/tester without npm ceremony. It should replace complexity, not create a third duplicate implementation.

## Browser-first multi-platform verification

The product's portability claim should be expressed as evidence tiers.

### Deterministic core matrix

**Enforced today:** config/install parity and `--list` presence for all five projects. **Executed by manual E2E dispatch:** the representative `@portable` subset runs across all five configured projects (desktop Chromium/Firefox/WebKit plus Android-oriented Chromium and iPhone/iOS-oriented WebKit emulation). This remains emulation/browser-engine evidence, not physical-device proof.

Configured target matrix:

- desktop Chromium;
- desktop Firefox;
- desktop WebKit;
- Android-oriented Chromium device profile;
- iPhone/iOS-oriented WebKit device profile;
- responsive/mobile layout assertions.

Mobile Playwright projects are intentionally constrained to tests tagged `@portable`; adding mobile profiles must not multiply the entire catalogue/E2E suite. The parity regression checks this configuration contract.

These are browser-engine/device-emulation claims only. Playwright WebKit is not branded Safari, and an iPhone descriptor is not a physical iPhone.

### Product integration

Against the real Flutter Web build, verify representative user paths rather than every historical screen:

- hub/tool navigation and back/deep-link behavior;
- input and output;
- responsive reachability;
- clipboard/file/photo paths where browser support exists;
- no hover-only essential control;
- overflow/long content;
- Unicode/IME-sensitive input;
- failure screenshot/trace/video artifacts.

### Real-device/platform tail

Target separately when a feature crosses an OS boundary:

- physical iPhone/iOS Safari;
- physical Android/Chrome;
- photo library/camera;
- HEIC/EXIF;
- permissions;
- share sheet/download/file picker;
- PWA/install behavior.

Passing emulation must never be recorded as physical-device proof.

## Layout philosophy

The design target is not visual novelty. Prefer a boring, reachable, testable layout over a modern-looking layout with fragile interaction.

A feature is portable only when its primary action remains reachable on desktop and mobile; touch interaction does not depend on hover; narrow layouts do not hide required controls; long content can scroll without trapping controls; and browser tests can locate important actions through stable DOM/accessibility semantics.

## Migration safety

For each proposed Dart -> Python/data/web/Deno migration:

1. name the current owner and caller;
2. state whether the code ships to the client;
3. define the platform contract;
4. show the dependency/setup delta;
5. keep one source of truth;
6. add behavior-parity tests before deleting the old owner;
7. measure CI/build/runtime impact when meaningful;
8. delete the displaced implementation in the same or immediately linked change;
9. preserve a rollback point;
10. never call an emulated browser result real-device compatibility.

## Suggested follow-up slices

1. **Tooling audit:** inventory `tool/*.dart` and classify keep-Dart / Python-stdlib / Deno / delete-or-merge. No migrations yet.
2. **Data audit:** identify static Dart catalogues that can become language-neutral assets without runtime duplication.
3. **Browser matrix:** add Android-oriented Chromium and iPhone/iOS-oriented WebKit projects to E2E and exact parity/evidence checks.
4. **Representative product paths:** choose a small set of real user flows for all browser projects; do not multiply thousands of catalogue tests by five projects.
5. **OS-boundary matrix:** photo/file/share/clipboard/location/storage capability table, with emulation vs real-device evidence separated.
6. **First migration:** choose one low-risk developer-only Dart tool where Python demonstrably reduces code/setup while preserving output contract.
7. **Reassess:** only then decide whether a browser-native HTML/JS or Deno slice should replace a heavier Flutter/Dart boundary.

## Success criterion

The repository succeeds when a maintainer can add a feature by asking “what is the lightest portable owner?” rather than “how do I implement this in Dart?”, while users retain stable access from desktop web, mobile web, Android-oriented browsers, iPhone/iOS-oriented browsers, and native Flutter surfaces where those surfaces provide real value.


## Related reusable knowledge

- [ANTI_PATTERNS.md](./ANTI_PATTERNS.md) consolidates repository incidents and review rules across Flutter/Dart, pytest/Python, Playwright/browser CI, media, and runtime ownership.
- [CROSS_REPOSITORY_REUSE.md](./CROSS_REPOSITORY_REUSE.md) evaluates what this repository can consume from sibling projects and what should be promoted outward, with lightweight provenance/versioning rules.

The intended direction is two-way reuse without turning sibling repositories into unpinned runtime or CI dependencies.
