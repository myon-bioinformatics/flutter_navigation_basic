# GitHub Actions workflow inventory (2026-10-11)

The workflow **file** is not the same as an individual job. Keep separate
workflows when they have materially different triggers, permissions, toolchains,
or evidence; avoid duplicating test implementations.

| Workflow | Purpose | Current decision |
| --- | --- | --- |
| `actionlint.yml` — Validate GitHub Actions | Validate workflow changes through parent reusable actionlint | Keep; parent `@main` is mutable, consider a pinned SHA when deliberately updating the parent contract |
| `claude.yml` — Claude | Comment/dispatch agent, OAuth and different permissions | Keep separate from CI |
| `curl-runtime.yml` — Python curl runtime browser contract | Containerized Python-enabled Flutter Web runtime E2E | Keep; distinct from static browser tests |
| `dart.yml` — Flutter | Primary Flutter/Android/iOS/test/JUnit matrix and main push gate | Keep |
| `diagnostics-evidence.yml` — Diagnostics screenshot evidence | Browser screenshots for diagnostics paths | Keep separate for artifact/evidence scope; consider narrowing broad `python/**` trigger only after measuring coverage |
| `docker-e2e-verify.yml` — Docker E2E snapshot generation (manual) | Manually build image and generate snapshot baselines with `--update` | Keep manual, renamed to avoid implying read-only verification |
| `flutter-pages.yml` — Flutter Web Pages | Deploy only after successful main Flutter workflow; deployment permissions | Keep separate |
| `non-dart.yml` — Non-Dart checks | Python/Playwright/browser adapter and canonical JUnit | Keep; real browser adapter smoke now also triggers when `test.py` or `multi_test_runner.py` changes |
| `ios-native.yml` — iOS native checks | iOS release compile and image-normalization XCTest | Run on native/bridge/dependency changes or manual dispatch; independent of Web Pages |
| `structure-refactor-validation.yml` — Refactor smoke | Fast Python/Flutter/Node producer regression on work branches | Keep; action versions aligned with other workflows |

## Workflow-level changes in PR #167

1. `playwright-smoke` is now `playwright-adapter-smoke`: it installs/list-checks
   browsers **and actually executes** the Python-wrapped Playwright adapter.
2. The adapter's native JUnit is named `junit-playwright-adapter-smoke` and
   becomes a **required expected report** when the E2E lane is selected.
   Its attempt history is a separate short-retention artifact.
3. The Non-Dart classifier selects the adapter smoke for changes to
   `python/multi_test_runner.py` or `python/test.py`, even when
   no `e2e/**` file changed. This avoids the previous evidence gap.
4. Refactor smoke now uses checkout/setup-python/setup-node v7, consistent
   with the other maintained CI workflows.
5. The manual Docker workflow title now explicitly says **snapshot generation**,
   because its `--update` behavior is not a read-only comparison.

No workflow has been deleted or merged: `curl-runtime`, diagnostics and the
full Playwright E2E are different proof surfaces, while Pages and Claude have
distinct permissions. The change does not assert that all suites test native
Android/iOS behavior. Browser emulation remains browser evidence only.

## Follow-up, not in this PR

### iOS native verification

iOS compile and Simulator XCTest now run in `ios-native.yml`, outside the
Flutter workflow that gates Pages. Web/view-only and Python-tooling changes do
not start macOS jobs. Native sources, dependency locks, the Dart image-normalize
adapter/limits, and image compatibility fixtures select iOS verification.
Before shipping a native app after other Dart changes, manually run this
workflow on that exact commit; Web success is not native-build proof.

The XCTest artifact retains its text log and `results.xcresult` bundle, including
failed runs. Use the existing Python Actions CLI to locate/download it:

```bash
python python/test.py --actions-latest --workflow "iOS native checks" --download-artifact ios-xctest-log
```

The iOS SDK pin must move together with the primary Flutter gate pin; a Python
contract test checks this. Android verification and Pages deployment conditions
are unchanged.

- Pin the actionlint reusable workflow to an immutable parent commit when its
  compatibility is verified, rather than silently using mutable `@main`.
- Measure whether the diagnostics workflow's broad `python/**` trigger
  is cost-effective before narrowing it.
- Review path-filter and JUnit-collection contracts after the new browser
  adapter smoke is green on the same PR head.
