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

This PR starts the app-wide migration from the current main branch without regressing Coordinate Tolerance / XYZ Tile, Bounding Box, or Home Refresh. Home chrome and the two location tools use the shared selector first; remaining implemented screens should migrate to the same catalog before this PR is considered complete.
