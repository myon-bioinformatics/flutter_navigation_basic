# Canonical entrypoint and build lanes (#102)

All Web and native builds use `lib/main.dart`, which starts through
`bootstrapApp` (`lib/shared/bootstrap/app_bootstrap.dart`).
Catalog load failure shows `StartupErrorApp` (semantics identifier
`startup-error`); preferences failure continues with in-memory `eng`.

| Lane | Entrypoint | Role / evidence provenance |
| --- | --- | --- |
| GitHub Pages | `lib/main.dart` | published Web app from the Flutter-gated main commit |
| Browser E2E / Docker | `lib/main.dart` (`E2E=true`) | browser evidence; semantics explicitly enabled |
| Pinned / latest-stable Web CI | `lib/main.dart` | release compile checks |
| iOS release / Simulator XCTest | `lib/main.dart` | native build and platform tests |
| Android arm64 size | `lib/main.dart` by default | measured APK; summary records the target |

The redundant legacy shell was removed. Its environment/storage initialization,
theme, navigator key and success log were not copied into the current app.
Existing reusable routes and feature code remain. No second deployment or
Deno/Python runtime was introduced: the removed shell was Flutter UI/bootstrap.

Evidence remains specific to its SHA, platform and flags. A common entrypoint
does not turn browser tests into proof of native runtime behavior, nor compare
new APK sizes directly with historical measurements of the legacy shell.
