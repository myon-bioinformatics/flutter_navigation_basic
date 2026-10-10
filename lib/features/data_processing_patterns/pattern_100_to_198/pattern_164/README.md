# Pattern 164: EventState

イベント→状態遷移パターン。

- 実処理: `tool/python/state_reducer.py` の `event_state` operation
- pytest: `tool/python/tests/test_state_reducer.py`
- 契約: `docs/state-reducer-patterns.md`
- Redux Storeやサブスクライバー、Flutter状態管理との完全互換は意図しない。
- 旧ダミーController／Model／Serviceは削除済み。
- Viewは説明画面であり、Python CLIの実行結果は未接続。
