# Pattern 147: EventLoop

イベントループの理解と制御。

## 責務
- 参照実装：`tool/javascript/event_loop_patterns.mjs`、mode `event_loop`
- 回帰テスト：`tool/javascript/tests/*.test.mjs`（`node --test`）
- 詳細：`docs/event-loop-patterns.md`
- FlutterのViewは説明用。Node実行への接続は未実装。Dart Stream/Future固有動作の完全互換ではない。
- 旧ダミーController/Model/Serviceは削除済み。
