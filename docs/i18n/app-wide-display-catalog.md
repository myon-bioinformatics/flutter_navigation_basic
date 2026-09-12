# App-wide display catalog

The display catalog is the source of truth for user-visible static UI text.

## Contract

- UI code references stable keys, not locale-specific branches.
- `DisplayController` owns one app-wide locale and persists it as `app.display.locale.v1`.
- Locale selects the value for a key; locale itself is not the source of truth.
- Supported locales use ISO 639-3 codes: `eng`, `jpn`, `fra`, `spa`, `por`, `ara`, `zho`, `rus`, `ind`, `deu`, and `swa`.
- The language picker shows the three-letter codes (`ENG` / `JPN` / …), not long language names.
- On read, legacy two-letter preferences migrate to ISO 639-3 (`en→eng`, `ja→jpn`, `fr→fra`, `es→spa`, `pt→por`, `ar→ara`, `zh→zho`, `ru→rus`, plus `id→ind` / `in→ind`).
- After migration, the preference store keeps the ISO 639-3 value under `app.display.locale.v1`.
- Required locale dictionaries must expose the same non-empty key set.
- Internally the app keeps ISO 639-3. When talking to Flutter `Locale`, HTML `lang`, or other BCP 47 surfaces, convert through `DisplayLocaleCodes` (e.g. `ind→id`, `deu→de`, `swa→sw`).
- User data, coordinates, URLs, IANA timezone IDs, API/MCP payloads, code snippets, and generated values remain untranslated data.
- New features add keys to `assets/display/app_text.json` instead of creating feature-local translation maps.

## Entity identifiers

First-party models, JSON, and APIs use lowerCamelCase `<entityName>Id` (for example `urlParamCaseId`, `screenDataId`, `timelineEntryId`, `clipboardShelfItemId`, `coordinateAreaCaseId`) instead of a bare `id`. Persisted Now Timeline entries still accept legacy `"id"` on read.

## Rollout

This PR continues the app-wide migration from the current main branch without regressing Coordinate Tolerance / XYZ Tile, Photo Studio, or Home Refresh. Migrated so far: Home (both entrypoints, including weekday chrome), Latitude/Longitude (incl. manual box), Photo Studio, Now Timeline, Clipboard Shelf, Clipboard Workbench, Counter Playground, Irony Generator, Composition Studio/Generator, URL Parameters, Navigation Hub, the shared GenericScreen chrome (App bar, use-case tabs, pattern chips), UI Showcase chrome, Mock API, and MCP Integration. UI Showcase's `UiShowcaseConfig` defaults (title/subtitle/sections) and the Data page's example `DataTable` rows stay untranslated intentionally — they demonstrate literal override/example values, not chrome. Any remaining implemented, non-empty user-facing static UI text should keep migrating to the same catalog.
