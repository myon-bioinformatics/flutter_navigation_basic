# App-wide display catalog

The display catalog is the source of truth for user-visible static UI text.

## Contract

- UI code references stable keys, not locale-specific branches.
- `DisplayController` owns one app-wide locale and persists it as `app.display.locale.v1`.
- Locale selects the value for a key; locale itself is not the source of truth.
- Supported locales are `en`, `ja`, `fr`, `es`, `pt`, `ar`, `zh`, and `ru`.
- Required locale dictionaries must expose the same non-empty key set.
- User data, coordinates, URLs, IANA timezone IDs, API/MCP payloads, code snippets, and generated values remain untranslated data.
- New features add keys to `assets/display/app_text.json` instead of creating feature-local translation maps.

## Rollout

This PR starts the app-wide migration from the current main branch without regressing Coordinate Tolerance / XYZ Tile, Bounding Box, or Home Refresh. Migrated so far: Home (both entrypoints, including weekday chrome), Latitude/Longitude, Bounding Box, Now Timeline, Clipboard Shelf, Clipboard Workbench, Counter Playground, Irony Generator, Composition Studio/Generator, URL Parameters, Navigation Hub, the shared GenericScreen chrome (App bar, use-case tabs, pattern chips), UI Showcase chrome, Mock API, and MCP Integration. UI Showcase's `UiShowcaseConfig` defaults (title/subtitle/sections) and the Data page's example `DataTable` rows stay untranslated intentionally — they demonstrate literal override/example values, not chrome. Any remaining implemented, non-empty user-facing static UI text should keep migrating to the same catalog.
