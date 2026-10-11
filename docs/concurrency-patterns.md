# Concurrency reference (138–143)

No npm packages. Use Node.js 22+ and run `node --test tool/javascript/tests/*.test.mjs`.
CLI: `node tool/javascript/concurrency_patterns.mjs --input request.json` (or JSON stdin).
Modes: `work_queue` 138, `semaphore` 139, `mutex` 140, `cancelable` 141, `parallel_map` 142, `progress` 143.
Tasks: `{"value":JSON,"delay_ms":0..50}`, up to 32 tasks. Work queue is serial, parallel map and semaphore use bounded workers, and cancellation covers pre-aborted jobs. Mutex demonstrates serialized state updates; this does not claim a shared-memory atomic lock. Progress reports completion counts for serial tasks. Errors exit 2 with no successful stdout JSON.

These are standalone JS reference operations, **not** Dart Isolate, Flutter compute, live Dart Future cancellation, or a Flutter-embedded JS runtime. The existing Dart placeholders should only be removed once CI and UI contracts pass.
