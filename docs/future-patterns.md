# Async reference catalogue (121–126)

The original Dart services were 100 ms delayed-success placeholders, not real Future implementations. Node.js 22+ has a dependency-free JSON CLI at \`tool/javascript/future_patterns.mjs\`, and its contract is checked by \`node --test tool/javascript/tests/*.test.mjs\`.

Input is a JSON object with \`mode\` and a single \`task\` (or \`tasks\` for wait/any); a task has \`value\`, optional \`delay_ms\` (0..1000), and optional nonempty \`reject\` string. CLI outputs \`{"schema":"future-patterns/1","mode":"...","value":...}\` on stdout; rejected/invalid inputs exit 2 with stderr only.

- 121 basic: Promise resolution.
- 122 chain: sequential \`add\`/\`multiply\`/\`uppercase\` steps via Promise.then.
- 123 error: rejected Promise is caught with a fallback and an error record.
- 124 wait: Promise.all, ordered results.
- 125 any: Promise.race (first settled, including rejection); **not** Promise.any (first fulfilled).
- 126 timeout: Promise.race with a timer, cleared on completion. This is **not** cancellation of the underlying job.

These are Node/JavaScript reference analogues, not behavioral parity claims for Dart Future scheduling/microtasks; no Dart/Flutter runtime calls Node. Flutter assets/UI remain separate responsibilities.
