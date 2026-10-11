# Patterns 091–099: Python validation producer (limited implementation)

## Responsibility and actual scope

- `tool/python/validation_patterns.py`: standalone Python 3 stdlib-only CLI, JSON stdin/stdout.
- `tool/python/tests/test_validation_patterns.py`: normal, invalid, boundary, and form aggregation contracts.
- Flutter `/screen091`–`/screen099` show the shared `ValidationPatternLinks` (source links only). The nine legacy `view.dart` files were never reachable from a route and have been removed. **No Flutter→Python execution bridge is wired yet;** interactive input runs in the local browser form below.

| Pattern | Operation | Contract / limitation |
|---|---|---|
| 091 ValidationBasic | `required` | Nonempty input check, not a form framework |
| 092 EmailValidation | `email` | Practical ASCII heuristic, not RFC-complete or deliverability check |
| 093 PasswordStrength | `password` | Minimum length and character categories, **not** a security-strength estimate |
| 094 PhoneValidation | `phone` | E.164-like digits, no regional numbering-plan verification |
| 095 UrlValidation | `url` | HTTP(S) syntax only, not SSRF protection or host safety |
| 096 DateValidation | `date` | Strict YYYY-MM-DD calendar date |
| 097 RangeValidation | `range` | Inclusive finite numeric bounds |
| 098 RegexValidation | `regex` | Named allowlist only; arbitrary user regex intentionally unsupported |
| 099 FormValidation | `form` | Aggregate field results; no Flutter form lifecycle |

## Handoff / next steps

1. Keep all nine as **限定実装（Python producer exists; Flutter unwired）** in the 198-row audit.
2. Add browser/Flutter UI wiring only when an actual execution path is defined; do not claim standalone CLI tests prove UI functionality.
3. When changing Views, record production Dart/test Dart deletions, case-level JUnit, browser operation and actual output.
4. Never present email/URL/password heuristics as authoritative security validation.

## ブラウザからの実入力（新規）

ローカルで以下を実行し、`http://127.0.0.1:8765/` を開く。

```sh
python3 -S tool/python/validation_http.py --port 8765
```

入力欄・検証種別・検証ボタンがあり、JavaScript `fetch` からPythonの `/validate` を呼び、実際の検証結果を表示する。サーバーは127.0.0.1にのみbindする開発用デモで、公開運用や個人情報の入力は想定しない。

ブラウザは同一オリジンの POST にも `Origin` を付ける。許可するのは、実際に bind したポートの `http://127.0.0.1:<port>` と `http://localhost:<port>`（`--port` やポート 0 でも、割り当て後のポート）に加え、明示的な追加オリジンだけである。追加オリジンの既定は Flutter Web 開発サーバーの `http://localhost:8080`（`flutter run -d web-server --web-port=8080` や portable Playwright が使う配信元）である。`--allow-origin` を省略するとこの既定が使われ、指定した場合はその値だけが追加オリジンになる（複数回指定できる）。`*` は拒否する。これは Flutter の `/screen091`〜`/screen099` への組込みではなく、その開発サーバーから API を呼ぶための CORS 許可だけを残したもの。許可しない Origin は、ほかの失敗と同じ形の JSON 403（`{"error":"origin not allowed"}`）になる。

**重要な境界:** Pythonの検証実行そのものはFlutterへ組み込んでいない。`/screen091`〜`/screen099` にはGitHub上の実装・テストへの静的導線を接続済みだが、Web配布環境でのPython API実行は提供しない。各パターンの完成度は引き続き**限定実装**。

テスト: `tool/python/tests/test_validation_http.py`（HTTP入力画面、実API応答、不正入力）。ブラウザ操作は `e2e/tests/validation_http.spec.ts` が空いているポートでこのサーバーを起動し、Chromium で検証ボタンから結果表示まで確認する。Non-Dart checks の Validation browser contract が、その JUnit を collector の必須レポートにする。portable の Flutter E2E とは別ジョブ。

## 番号付きFlutterルートへの接続方針（2026-10-11）

現状の `/screen091`〜`/screen099` は `ValidationPatternLinks` に接続済みで、GitHub上の実装・テスト・ローカル入力画面ソースへのURLを表示・コピーできる。ブラウザフォーム自体は独立したloopback Python HTTPサーバーで提供される。
Flutter Webから `http://127.0.0.1:8765/` を直接開くことを正式導線にしない。
ユーザー端末のloopbackとCI/ホスティングサーバーのloopbackは異なるため。

GitHub PagesではPython APIを常駐させず、静的なGitHubリンクを正式な導線とする。Python検証を実行する場合はローカルHTTPデモを利用する。
ただし静的なGitHub PagesのみではPythonサーバーを実行できないため、
デプロイ先が決まるまではFlutter側に偽の実行ボタンを置かない。

既存の `e2e/tests/validation_http.spec.ts` はブラウザから実際に
入力→POST→JSON結果表示を4ケースで確認する。これはFlutter番号付きルートのE2Eではない。

完了条件: 091〜099の各画面で入力・検証結果・異常時表示を操作でき、
Pythonの実処理と一致することをPlaywright/JUnitで確認する。

## GitHub Pages向け番号付きルート（PR #145）

`/screen091`〜`/screen099` は共通 `ValidationPatternLinks` を表示し、
対応するPython実装・テスト・ローカル入力画面・利用方法へのGitHub URLを
選択・コピーできる。Dartの処理重複やGitHub Pages上のPython常駐は不要。

GitHub Pages のビルドは `--dart-define=SOURCE_REF=<deploy した commit>` を渡すので、
公開画面のリンクはそのコミットに固定される。`SOURCE_REF` を渡さないビルドは main を指す
（マージ前は main にファイルがないため、PR のビルドでは 404 になりうる）。**現時点では外部ブラウザを直接開くボタンではなく、
URLのコピー操作**である。

テスト: `test/features/data_processing_patterns/validation_pattern_links_test.dart`。
9ルートの表示とコピー操作をFlutter smoke/JUnitで検証する。
