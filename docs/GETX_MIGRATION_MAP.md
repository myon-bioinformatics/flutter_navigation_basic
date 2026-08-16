# GetX dependency map and staged migration

This document tracks removal of GetX from the application while preserving the repository's reference catalogue. The goal is to keep production/handcrafted code Flutter-native and isolate framework-specific examples instead of replacing one broad framework dependency with another.

## Current position

The **application shell is now GetX-free**:

- `lib/main.dart` already uses `MaterialApp`.
- `lib/main_prod.dart` now uses `MaterialApp` rather than `GetMaterialApp`.
- `lib/core/navigation/app_navigation.dart` uses Flutter `Navigator` + a `GlobalKey<NavigatorState>` and a standard `Map<String, WidgetBuilder>` route registry.
- handcrafted Home / Counter / Irony / Composition / Screen 5 pages use ordinary `StatelessWidget` / `StatefulWidget`, explicit constructor injection, plain Dart controllers, and `ChangeNotifier` only where mutation is required.
- CI rejects any new `package:get/get.dart` import in that handcrafted shell.

`get` remains in the root dependency graph **only because historical/generated reference-pattern files still compile as part of this package**. The remaining work is therefore catalogue isolation/migration, not application-runtime migration.

## Coupling map

| Responsibility | Previous GetX API | Current application replacement | Status |
|---|---|---|---|
| App bootstrap | `GetMaterialApp` | `MaterialApp` | ✅ migrated |
| Named navigation | `Get.toNamed`, `Get.offAllNamed`, `Get.back` | `NavigatorState.pushNamed*` / `maybePop` | ✅ migrated |
| Route table | `GetPage` | `Map<String, WidgetBuilder>` | ✅ migrated |
| Dependency lookup / bindings | `BindingsBuilder`, `Get.lazyPut`, `Get.find` | explicit constructor injection | ✅ migrated for handcrafted shell |
| Handcrafted controller state | `GetxController`, `.obs`, `Obx` | plain Dart / `ChangeNotifier` + `ListenableBuilder` | ✅ migrated |
| Handcrafted view binding | `GetView<T>` | ordinary Flutter widgets | ✅ migrated |
| Shared legacy controller base | `BaseController extends GetxController` | still required by generated/reference patterns | ⏳ catalogue-only boundary |
| Historical/generated pattern catalogue | mixed GetX APIs | isolate or migrate by verified batches | ⏳ remaining |

## Rules for new work

1. **No new GetX coupling in application code.** API/MCP/auth/cache/streaming work uses Dart/Flutter SDK capabilities unless it is intentionally demonstrating GetX as a reference pattern.
2. **Use the smallest state primitive that fits.** Prefer local `setState`; then `ValueNotifier`/`ChangeNotifier`; introduce broader abstractions only when the requirement demonstrates a need.
3. **Prefer constructor injection.** New services are passed explicitly rather than registered in a global service locator.
4. **Keep integration code UI-agnostic.** API/MCP/auth/cache clients remain plain Dart where possible.
5. **Do not mechanically rewrite all 792 patterns without a regression plan.** Catalogue migration must preserve the educational meaning of patterns that intentionally compare state/navigation approaches.

## Remaining migration stages

### Stage D — isolate shared legacy infrastructure

- Identify reference patterns that inherit `BaseController` only for common loading/error fields versus those that genuinely demonstrate GetX lifecycle/reactivity.
- Introduce a Flutter/Dart-native reference base only where behavior can be preserved mechanically and verified in batches.
- Keep deliberately GetX-specific patterns explicit rather than disguising them behind compatibility shims.

### Stage E — separate or migrate the catalogue dependency

Preferred end state:

- production/handcrafted app remains GetX-free;
- generic reference patterns use Flutter/Dart primitives;
- intentionally GetX-specific examples live behind an explicit example/package boundary with their own dependency declaration.

At that point `get` can be removed from the root `pubspec.yaml` entirely while comparative GetX examples remain available if they are still useful.

## Version policy

The repository uses two CI compatibility lanes:

1. a pinned stable Flutter version for reproducible lockfile/analyze/test/build results;
2. the moving `stable` channel to detect compatibility problems with the newest stable Flutter SDK.

Tracked direct packages are also checked against the latest stable pub.dev versions. Prerelease/RC versions are not used merely to satisfy a "latest" label.

## Completion criteria

Full root-level GetX removal is complete when all of these are true:

- application bootstrap and navigation remain Flutter-native;
- handcrafted features remain GetX-free under CI enforcement;
- `BaseController` and generic catalogue patterns no longer require GetX;
- intentionally GetX-specific examples are isolated behind a separate dependency boundary or removed;
- `get` can be deleted from the root `pubspec.yaml` without excluding real application code from analysis/tests.

Until that final catalogue step, retaining `get` is a documented reference-only compatibility decision rather than application architecture.
