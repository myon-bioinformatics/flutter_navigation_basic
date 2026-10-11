# データ処理198パターン：監査・責務分離・引継ぎ

## 最新の全件一覧を見る

PR #145 の **Refactor smoke** ワークフローを開き、同一headの artifact
`data-pattern-status-198` を取得する。Markdown `pattern-status.md`
に001〜198の全件を番号順に記録する。JSON原本は
`data-pattern-responsibility` の `pattern-responsibility.json`。

- PR: https://github.com/myon-bioinformatics/flutter_navigation_basic/pull/145
- CI: https://github.com/myon-bioinformatics/flutter_navigation_basic/actions/workflows/structure-refactor-validation.yml
- 監査本体: `tool/python/pattern_responsibility_audit.py`
- 可読表の生成: `tool/python/render_pattern_status.py`

ローカル生成（Python標準ライブラリのみ）：

```sh
python3 -S tool/python/pattern_responsibility_audit.py --json --check > pattern-responsibility.json
python3 -S tool/python/render_pattern_status.py pattern-responsibility.json pattern-status.md --head "$(git rev-parse HEAD)"
```

**必ずheadを照合すること。** CIの成功・失敗・実行中を区別し、別コミットの監査表を最新結果として扱わない。

## 方針・思想

1. **Dart縮小は明確な目標。** ただし実機能を消して数だけ減らさない。
2. 処理はPython優先。ブラウザイベント・非同期はJS/Node/TS/Denoを検討。
   Dartはほかでは代替しづらいView・ジェスチャー・ネイティブ処理に限定する。
3. 独立Python/JS処理が動くことと、Flutterから実際に利用できることは別。
   ダミー成功ボタンは機能として数えず、未接続は**限定実装**と記録する。
4. Controller/Service/Modelと旧テストの削除時は、参照・README・画面導線・
   Flutter analyze/Widget/Playwright/Python/Node・JUnitを確認する。
5. パターンの存在、producerの存在、画面接続、実操作成功、完全実装を混同しない。
   静的監査だけで完全実装と断定しない。
6. 各変更について「責務の移管元・移管先」「本番Dart削減」「テストDart削減」
   「新しく動く機能」「テスト件数・環境」「完成度」「残課題」を記録する。
7. PR #145は検証が完了するまで未マージとし、同一headのCI ALL GREENを確認する。

## 到達性（2026-10-11 からの監査基準）

アプリ本体から `lib/features/*_patterns` への import は 0 件で、各パターンの `view.dart` は
どの route からも到達しない。そこで監査の第一の軸を「`/screenNNN` が実際に何を表示するか」に変えた。

- 期待値: `tool/ci/numbered_routes.toml`（**人が書く**。198 件の行き先 Widget。コメント可）
- 実測: `test/core/navigation/numbered_routes_observation_test.dart` が 198 本の route を実行時に解決し、
  `build/test-results/route-observations.json` に Widget の種別と id を書き出す（**機械が書く**。期待値は読まない）。
- 判定: `tool/python/check_route_observations.py` が TOML と JSON を照合し、件数・種別・id の
  どれかが違えば失敗する。Refactor smoke で実測の直後に実行する。
- 監査: `route`（Widget）、`reachability`（`shared` / `dedicated` / `generic`）、`provision`
  （`shared_interaction` / `shared_source_links` / `shared_native_example` / `dedicated_feature_page` / `generic_catalogue`）、
  `legacy_view`（`unreachable` / `absent`）を各行に出す。routes.dart の正規表現解析は撤去した。
- `status`（下の分類）はディレクトリ内コードの証跡として**従来どおり**残す。たとえば
  `native_flutter_example` は「アプリから到達しない Flutter の例」であり、route の行き先は `generic_catalogue`。
  旧 View を削除して数が変わっても、機能の増減ではなく未到達コードの整理である。
- 共通 Widget に route が実証されたパターンは `view.dart` を必須にしない（`shared_widget_route`）。

## 分類の読み方

- `fake_delayed_success`: 固定成功文言のダミー。機能未実装。
- `description_only`: 説明表示のみ。機能未実装。
- `standalone_cli_ui_unwired`: 独立処理は存在するがFlutter実行未接続。限定実装。
- `precomputed_asset_view`: 事前生成アセット表示。限定実装。
- `native_flutter_shared_interaction`: 共通操作Widgetあり。実操作の証跡を別途確認。
- `native_flutter_example`: Flutter側の例あり。環境別・実機能の証跡を別途確認。

**引継ぎ時の完了条件**: 198件全件の状態を残し、差分と未解決事項を追跡する。
完全実装 は、仕様上の振る舞い・実行導線・実テストを確認した場合のみ手動認定する。
