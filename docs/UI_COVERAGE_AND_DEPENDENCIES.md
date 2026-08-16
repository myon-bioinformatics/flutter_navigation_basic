# UI coverage, generalization, and dependency audit

This document defines the completion line for the presentation layer before the repository shifts its main effort to functional integrations such as API and MCP connectivity.

## Goal

Keep a reusable set of common Flutter screens that:

- covers representative mobile, tablet, web, and desktop navigation/layout patterns;
- demonstrates light, dark, modern, retro, and terminal-like presentation without a UI framework dependency;
- keeps business/integration logic replaceable while the presentation shell remains stable;
- prefers Dart/Flutter SDK APIs when they are sufficient;
- uses external configuration for replaceable content/defaults and internal configuration for safe fallback behavior;
- avoids multiplying nearly identical screens after a representative pattern is already covered.

## Coverage inventory

| Area | Current coverage | Completion rule |
|---|---|---|
| Top-level shell | `Scaffold`, `AppBar`, cards, scrolling layouts | Covered |
| Side navigation | `Drawer`, Material 3 `NavigationDrawer`, `NavigationRail` patterns already exist; UI Showcase demonstrates responsive Rail → Drawer | Covered |
| Bottom navigation | Bottom navigation patterns exist; UI Showcase uses `NavigationBar` on compact layouts | Covered |
| Tabs / nested content | Tab patterns and `TabBar`/`TabBarView` are represented in the catalogue | Covered |
| Dialog / sheet / modal | Dialog, BottomSheet, Drawer ranges are represented in navigation patterns | Covered |
| Forms / controls | Text fields, buttons, chips, switches, sliders, dropdowns and segmented controls are represented across catalogue and mini apps | Covered |
| Progressive disclosure | `ExpansionTile` and detail tabs | Covered |
| Data presentation | Lists, grids, tables, paging/data-processing families; UI Showcase includes `DataTable` | Covered |
| Responsive layout | mobile/tablet/web/desktop category plus responsive showcase shell | Covered |
| Accessibility | semantics category plus explicit semantics in mini apps | Covered |
| Light / dark | UI/theme catalogue plus runtime System / Light / Dark switch in UI Showcase | Covered |
| Modern | Material 3 default style | Covered |
| Retro / terminal | lightweight style variants in UI Showcase, no theme package | Covered representative sample |
| Image | Base64 external setting → `dart:convert` → `Image.memory` | Covered |
| Video | No package added solely for catalogue completeness | Optional until a real playback requirement exists |

The catalogue should now prefer **representative completeness** over adding more cosmetic permutations. New UI entries should be added only when they introduce a materially different interaction, accessibility requirement, layout model, or platform behavior.

## Generalized screen configuration

`UiShowcaseConfig` uses two layers:

1. **Internal defaults** in Dart. These guarantee a valid screen even when an external file is missing or malformed.
2. **External overrides** in `assets/ui_showcase.json`. These can replace title, subtitle, initial style/brightness, section labels, and embedded image data without changing widget logic.

Invalid or incomplete external configuration falls back to internal defaults. The external file is data/configuration, not executable presentation logic.

For build/deployment configuration, `core/config/AppConfig` now uses `String.fromEnvironment` and `--dart-define` instead of shipping `.env` files as Flutter assets.

Example:

```bash
flutter run \
  --dart-define=APP_NAME=FlutterNavigationBasic \
  --dart-define=API_BASE_URL=https://api.example.com \
  --dart-define=LOG_LEVEL=info
```

## Dependency audit

### Removed in this change

| Dependency | Previous purpose | Replacement |
|---|---|---|
| `intl` | Home date formatting | `DateTime` + small local formatter |
| `logger` | formatted logging | `dart:developer` while preserving `LoggerService` API |
| `flutter_dotenv` | runtime `.env` asset loading | `String.fromEnvironment` / `--dart-define` |
| `cupertino_icons` | starter-project icon package | unused; Flutter Material icons/catalogue code does not import it |
| `mockito` | test utility | unused |
| `mocktail` | test utility | unused |

### Retained intentionally

| Dependency | Coupling | Decision |
|---|---|---|
| `get` | **High** | Widely embedded in legacy/generated pattern architecture (`GetView`, `GetxController`, routing/state). Do not bulk-remove in one cleanup PR; migrate by responsibility using [`GETX_MIGRATION_MAP.md`](GETX_MIGRATION_MAP.md). |
| `shared_preferences` | Low/medium | Isolated behind `StorageService`; it provides actual platform persistence not supplied by core Dart. Keep unless persistence requirements change. |
| `flutter_lints` | Dev only | Lightweight static-analysis rules; keep. |

## GetX migration boundary

GetX is the one dependency comparable to a high-level framework abstraction rather than a thin adapter. The concrete coupling map, rules for new work, staged migration order, and removal criteria are maintained in [`GETX_MIGRATION_MAP.md`](GETX_MIGRATION_MAP.md).

The short policy is:

1. new/handcrafted screens use `Navigator`, `StatefulWidget`/`ValueNotifier`, and standard Flutter APIs by default;
2. legacy GetX usage is migrated by responsibility: routing, state/reactivity, dependency lookup, and convenience UI calls;
3. each responsibility is removed only when the corresponding behavior and tests remain equivalent;
4. the 792 pattern modules are not rewritten wholesale merely to reduce a dependency count.

## Presentation-layer completion rule

UI work can enter maintenance mode when all of the following remain true:

- representative navigation shells are covered, including sidebar/rail/drawer and compact navigation;
- common controls, forms, tables/lists, modal surfaces and responsive layouts are covered;
- System/Light/Dark plus representative Modern/Retro/Terminal presentation is demonstrable;
- image rendering works without a dedicated media dependency;
- external data/config can change labels/default presentation while internal defaults preserve a valid screen;
- additions after this point are driven by real functional requirements rather than cosmetic permutation count.

Once this line is met, feature work should primarily target API/MCP/auth/cache/retry/streaming/file/media integration while preserving these shared presentation contracts.
