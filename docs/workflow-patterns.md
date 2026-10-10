# Portable list/workflow contracts for 176–198

Uses Python stdlib only; call `python -S tool/python/workflow_patterns.py` with a
JSON request via stdin or `--input`, and verify using
`python -m pytest tool/python/tests/test_workflow_patterns.py -q`.

Operations are intentionally bounded in-memory reference behaviors, **not**
database transaction, real broker, distributed Saga, durable Outbox,
production scheduling, worker processes, or persistence. This avoids portraying
the old Dart 100 ms delayed-success stubs as real implementations.

List manipulation: swap(176), move_top(177), move_bottom(178),
insert_sorted(179), undo_redo(180), command(181), memento(182),
position_swap(185). The latter history modes share one bounded command model.

Backend references: batch(186), transaction(187), event_driven(188),
pubsub(189), queue(190), saga(191), outbox(192), event_sourcing(193),
cqrs(194), scheduler(195), worker(196), checkpoint(197), pipeline(198).

JSON request fields depend on operation. Success returns schema
`workflow-patterns/1`, operation and result. Invalid requests exit 2.
State/history, ordering and negative paths are exercised in pytest.
Flutter screens are not connected to this CLI; interactive mobile/Web UX
requires a separate explicit runtime/asset boundary.
