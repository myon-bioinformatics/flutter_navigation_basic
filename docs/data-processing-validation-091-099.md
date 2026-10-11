# Patterns 091–099: Python validation producer (limited implementation)

## Responsibility and actual scope

- `tool/python/validation_patterns.py`: standalone Python 3 stdlib-only CLI, JSON stdin/stdout.
- `tool/python/tests/test_validation_patterns.py`: normal, invalid, boundary, and form aggregation contracts.
- Existing Flutter `view.dart` files remain unchanged. **No Flutter→Python execution bridge or interactive validation form is wired yet.**
- No production/test Dart files were removed in this slice. This is a new producer, not a completed UI migration.

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

**重要な境界:** これはPythonで提供するブラウザ入力画面であり、Flutterの `/screen091`〜`/screen099` への組込みではない。Flutter画面への導線・Web配布環境でのAPI配置・Playwright E2Eは未実装。各パターンの完成度は引き続き**限定実装**。

テスト: `tool/python/tests/test_validation_http.py`（HTTP入力画面、実API応答、不正入力）。ブラウザ自動操作は別途必要。
