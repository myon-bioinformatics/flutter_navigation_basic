# Stream reference operations 127–135

External-dependency-free Node.js 22+ ESM: `tool/javascript/stream_patterns.mjs`.
Run `node --test tool/javascript/tests/*.test.mjs` and pipe JSON to the CLI.
Event input uses nondecreasing `at_ms` (0–60000) and JSON `value`, up to 1000 events.

127 basic: async generator; 128 controller: add/close commands; 129 broadcast: fanout snapshots; 130 transform: where_equals/map_add/expand; 131 merge: stable timestamp merging; 132 debounce: trailing; 133 throttle: leading; 134 buffer: fixed-sized groups; 135 window: complete sliding groups.

Time operators are **deterministic event-time replay**, not real-time clocks. Broadcast fanout is not Dart live subscription; no claim of Dart Stream parity for pause/resume, backpressure, microtasks or cancellation. Flutter execution bridge is not yet connected.
