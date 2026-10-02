# Entrypoints and build lanes (#102)

Both entrypoints start through `bootstrapApp` (`lib/shared/bootstrap/app_bootstrap.dart`).
Shared policy: catalog load failure shows `StartupErrorApp` (semantics identifier
`startup-error`); preferences/storage failure continues with in-memory `eng`.

| Lane | Entrypoint | Role / evidence provenance |
| --- | --- | --- |
| GitHub Pages (`flutter-pages.yml`) | `lib/main.dart` | published web app |
| Browser E2E / Docker (`non-dart.yml`) | `lib/main.dart` (`E2E=true`) | evidence for the Pages entrypoint only |
| `dart.yml` web build | `lib/main_prod.dart` | production-entrypoint compile check; NOT the Pages artifact |
| iOS build / XCTest | `lib/main_prod.dart` | native entrypoint |

`main_prod.dart` keeps production-only init (`AppConfig`, `StorageService`,
`LoggerService`, `AppNavigation.navigatorKey`, `AppTheme`) explicit; `main.dart`
does not run it. Evidence from one entrypoint must not be attributed to the other.

## Maintainer follow-up (cannot be edited by the bot)
In `.github/workflows/dart.yml` rename the two `Build production entrypoint ...`
web steps (lines ~165, ~327) to e.g. `Build web (main_prod.dart compile check, not the Pages artifact)`.
