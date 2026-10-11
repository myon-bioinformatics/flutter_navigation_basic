# Pattern 146: RxLike

RxDart 風の Reactive 実装 (標準 Stream)。

## 責務
- 参照実装：`tool/javascript/event_loop_patterns.mjs`、mode `reactive`
- 回帰テスト：`tool/javascript/tests/*.test.mjs`（`node --test`）
- 詳細：`docs/event-loop-patterns.md`
- FlutterのViewは説明用。Node実行への接続は未実装。Dart Stream/Future固有動作の完全互換ではない。
- 旧ダミーController/Model/Serviceは削除済み。
