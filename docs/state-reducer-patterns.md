# Patterns 164–165: pure state/event reducer

A Python standard-library JSON CLI provides a bounded real state transition engine.

```sh
echo '{"mode":"redux","initial":0,"actions":[{"type":"increment","value":2}]}' | python -S tool/python/state_reducer.py
python -m pytest tool/python/tests/test_state_reducer.py -q
```

`mode` is `event_state` (164) or `redux` (165).
`initial` is a bounded integer; `actions` is an ordered list of up to 1000
commands with types `set`, `increment`, `decrement`, or `reset`.
The output includes final `state` and the full `history`.
Invalid requests fail with exit code 2 and no JSON stdout.

The Redux mode demonstrates pure reducer ordering **only**; there is no Redux
Store, middleware, subscriber API, Flutter widget state, or persistence.
The EventState mode demonstrates event-to-state reduction, not a Flutter lifecycle.
Both old Dart Services were delayed-success placeholders, not real reducers.
