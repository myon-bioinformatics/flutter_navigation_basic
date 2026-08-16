# GetX dependency map and staged migration

This document turns the remaining high-coupling dependency into an explicit migration boundary. The goal is not to rewrite the catalogue in one sweep; it is to prevent new coupling and remove existing coupling by responsibility when a change is already touching that area.

## Current position

`get` remains the only intentionally retained high-coupling application dependency after the UI/dependency slimming work.

Repository search shows GetX is not confined to one adapter. It appears in production bootstrap/navigation code, shared controller infrastructure, handcrafted feature pages/controllers, and generated/reference pattern families. Representative examples include:

- `lib/main_prod.dart` — `GetMaterialApp` bootstrap.
- `lib/core/navigation/app_navigation.dart` — `Get.toNamed`, `Get.offAllNamed`, `Get.back`, `GetPage`, `BindingsBuilder`, and `Get.lazyPut`.
- `lib/core/services/base_controller.dart` — shared controller inheritance/reactivity boundary.
- handcrafted feature pages such as `lib/features/screen5/presentation/screen5_page.dart` — `GetView`-style presentation coupling.
- many files under the 792-pattern reference families — GetX is part of the historical/generated reference architecture, not a single removable import.

That spread means deleting the package directly would be an architecture migration rather than dependency cleanup.

## Coupling map

| Responsibility | Typical GetX API | Standard-first replacement | Migration risk | Policy |
|---|---|---|---|---|
| App bootstrap | `GetMaterialApp` | `MaterialApp` / `MaterialApp.router` | Medium | Migrate after routing table no longer requires `GetPage`. |
| Named navigation | `Get.toNamed`, `Get.offAllNamed`, `Get.back` | `Navigator`, named routes, or Router APIs | Medium | New handcrafted code should prefer Flutter navigation. Existing routes migrate as a coherent slice. |
| Route table | `GetPage` | `routes`, `onGenerateRoute`, or Router configuration | Medium/high | Do not maintain duplicate route registries long-term. Convert together with bindings. |
| Dependency lookup / bindings | `BindingsBuilder`, `Get.lazyPut`, `Get.find` | constructor injection / explicit ownership | High where pervasive | Prefer explicit constructor dependencies in new code. Remove service-locator use at feature boundaries first. |
| Controller base classes | `GetxController` | plain Dart controller, `ChangeNotifier`, `ValueNotifier`, or widget-owned state | Medium | Choose the smallest Flutter/Dart primitive that preserves behavior. |
| Reactive values | `.obs`, `Obx`, `Rx*` | `ValueNotifier` / `ValueListenableBuilder`, `ChangeNotifier`, `setState` | Medium | Migrate only when touching the feature; avoid framework-for-framework replacement. |
| View binding | `GetView<T>` | `StatelessWidget` / `StatefulWidget` with explicit dependency | Low/medium | Good early migration target for handcrafted screens. |
| Convenience UI | GetX snackbars/dialog helpers | `ScaffoldMessenger`, `showDialog`, `showModalBottomSheet` | Low | Prefer Flutter APIs immediately in new code. |
| Historical/generated pattern catalogue | mixed GetX APIs | depends on the pattern being demonstrated | High volume | Preserve behavior; migrate opportunistically or by generated batch with dedicated tests. |

## Rules for new work

1. **No new GetX coupling by default.** New API/MCP/auth/cache/streaming work should use Dart/Flutter SDK capabilities unless an existing GetX boundary must be crossed.
2. **Use the smallest state primitive that fits.** Prefer local `setState`; then `ValueNotifier`/`ChangeNotifier`; only introduce broader abstractions when the requirement demonstrates a need.
3. **Prefer constructor injection.** New services should be passed explicitly rather than registered in a global service locator.
4. **Keep integration code UI-agnostic.** API/MCP/auth/cache clients should remain plain Dart where possible, so navigation/state-library choices do not leak into functional integrations.
5. **Do not rewrite all 792 patterns to remove one package.** Large mechanical migration requires its own scope, generated verification, and regression plan.

## Recommended migration order

### Stage A — stop growth

- New handcrafted screens: no new `GetView`, `GetxController`, `.obs`, or `Get.*` calls unless required by an existing boundary.
- New integration/service layers: plain Dart interfaces and implementations.
- Use Flutter-native snackbar/dialog/navigation APIs in new work.

### Stage B — low-risk handcrafted edges

- Replace `GetView<T>` on small non-generated screens with ordinary widgets plus explicit controller ownership/injection.
- Replace isolated convenience UI calls.
- Replace local reactive fields with widget state or `ValueNotifier` when behavior is simple.

### Stage C — application navigation boundary

- Introduce one Flutter-native route registry.
- Convert route bindings to explicit object construction/ownership.
- Move `GetMaterialApp` to `MaterialApp` only after route and binding semantics are equivalent.

### Stage D — shared controller infrastructure

- Remove `GetxController` from shared bases after remaining handcrafted callers no longer depend on its lifecycle/reactivity semantics.
- Keep persistence/network/config services independent from UI state management.

### Stage E — reference catalogue

- Migrate pattern families only when it improves the pattern itself or when a generated batch can be verified safely.
- Keep patterns whose purpose is specifically to demonstrate GetX/state-management alternatives; the catalogue may intentionally retain comparative examples even after the application shell no longer depends on GetX.

## Completion criteria

The application can remove `get` from `pubspec.yaml` when all of these are true:

- app bootstrap no longer uses `GetMaterialApp`;
- the primary application route registry does not use `GetPage`;
- application navigation does not depend on `Get.*`;
- shared application controllers/services do not require `GetxController` or global GetX lookup;
- any remaining GetX code is explicitly isolated as reference/example material and can be moved behind a separate example dependency boundary, or removed if no longer valuable.

Until then, retaining `get` is deliberate rather than accidental.
