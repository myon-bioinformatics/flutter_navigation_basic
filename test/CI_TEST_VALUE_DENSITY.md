# CI Test Value Density

This branch intentionally focuses on test-only improvements stacked on top of PR #38.

Goals:

- eliminate pathological 10-minute widget-test timeouts by fixing shared test setup/lifecycle causes rather than extending timeouts;
- make representative widget tests complete in seconds under normal conditions;
- prefer bounded `pump()` / explicit async completion over broad `pumpAndSettle()` where possible;
- keep one clear behavioral purpose per test and remove duplicated setup/assertion work that does not add regression value;
- use unit tests for pure logic and widget tests for UI integration/interaction contracts;
- keep `DisplayScope` / `DisplayController` test setup deterministic and disposable;
- avoid production/runtime changes unless a genuine testability defect makes them unavoidable and the exception is documented;
- avoid new dependencies unless absolutely necessary.

Representative suites to validate first:

- Bounding Box
- Home Overview
- Clipboard Shelf / Workbench
- Composition Studio

Then run the full Flutter test suite and report elapsed-time improvement where comparable CI data exists.
