# Pattern 121–198 responsibility matrix

This tracks **intended ownership**, not claims that every operation is implemented.
"JS" means a dependency-free Node/JavaScript reference CLI, not a mandatory Vue
framework or JavaScript embedded in Flutter. A Vue UI may be introduced only if
browser interactivity truly requires it. Existing stub Service `Future.delayed`
is not regarded as implemented behavior.

| Patterns | Primary owner | Flutter's remaining obligation | Status |
|---|---|---|---|
| 121–126 Future | JavaScript Promise | display/real Flutter async boundary if later needed | JS implemented; Flutter not wired |
| 127–135 Stream/buffering | JavaScript async iterator / event stream | actual Dart Stream semantics only if required by UI | planned |
| 136–137 Isolate/compute | Flutter (native runtime) | Isolate scheduling, compute behavior | retain until real test |
| 138–150 queue, locks, throttling, async generator | JS / Node for event-loop concepts; Python asyncio for backend work | only platform-specific scheduling if present | planned |
| 151–156 GetX catalogue | Flutter ValueNotifier shared native UI; GetX-specific samples explicitly retired | native state/lifecycle only, no false GetX parity | implemented; Flutter widget tests |
| 157–170 notifier/inherited/state/MVC | Flutter for widgets/notifiers; Python or JS for pure state transitions | widget propagation, lifecycle and rendering | planned |
| 171–175 drag, reorder, animation | Flutter | touch/drag/animation, widget-specific interactions | planned |
| 176–179 swap/move/sorted insert | Python | render lists / forward user commands | planned |
| 180–182 undo/redo, command, memento | Python state operations (or JS for browser interaction) | user-facing undo UI only | planned |
| 183–185 multi-select and drag/position | Flutter gesture/selection + Python pure list operations | gesture layer and selection | planned |
| 186–198 batch, transaction, pubsub, CQRS, workflow | Python stdlib core; JS for browser events when useful | display + lifecycle only | planned |

## Removal gate

1. Verify each old Dart Service contains no real computation beyond a stub.
2. Implement real behavior and negative tests in the chosen portable runtime;
   do not portray a JS Promise analogue as identical to Dart Future behavior.
3. Remove obsolete GetX Controller, message-only Model and placeholder Service
   only after producer tests are green.
4. Preserve catalogue title/description and update README/Widget checks.
5. Run Refactor smoke: Python pytest, Node tests, Flutter Widget tests,
   `flutter analyze --no-fatal-infos`, and `flutter build web`.
6. UI-native functionality cannot be declared transferred by removing Dart
   files: it must have its own Flutter test or deliberately be documented as
   illustrative/not implemented.
