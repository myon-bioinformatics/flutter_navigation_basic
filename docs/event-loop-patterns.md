# Event loop and reactive reference operations 144–150

No npm dependencies. Node.js 22+ native ES module + built-in test runner.

- 144 Debounce and 145 Throttle reuse `tool/javascript/stream_patterns.mjs` in deterministic event-time replay mode. No extra implementation or dependency.
- 146 Reactive stream-like transformation uses `tool/javascript/event_loop_patterns.mjs` mode `reactive` (bounded map/filter).
- 147 EventLoop mode `event_loop` traces synchronous work, queued microtask, then timer.
- 148 MicrotaskQueue mode `microtask` traces sync, microtask, resolved Promise, timer.
- 149 SuspendResume mode `suspend_resume` models an ordered pause/resume checkpoint only; it **does not** implement Dart StreamSubscription.pause/resume.
- 150 AsyncGenerator mode `async_generator` uses JavaScript async generators.

Run `node --test tool/javascript/tests/*.test.mjs`. For event_loop_patterns CLI, pipe JSON or use `--input file.json`. Mode results use schema `event-loop-patterns/1`.

All modes are bounded reference operations. No claims about Dart-specific event loop, scheduling, lifecycle, widget timing, JS in Flutter, or actual subscription control. The Flutter views are informational until a distinct runtime/asset bridge is implemented.
