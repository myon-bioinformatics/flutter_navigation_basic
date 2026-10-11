# Patterns 103–105, 107, 109–110: conversion producer

説明表示だけだった6パターンに、Python標準ライブラリのみの独立処理を追加した。

| ID | 処理 | 実装範囲 |
|---:|---|---|
| 103 | DataNormalize | trim + NFC/NFKC + case変換 |
| 104 | TypeCoercion | int/float/boolの明示的な安全変換 |
| 105 | DateConvert | ISO / YYYYMMDDの暦日変換 |
| 107 | UnitConvert | 長さ(m/km/cm)・重量(kg/g) |
| 109 | Encoding | UTF-8文字列とBase64の相互変換 |
| 110 | DataMasking | 末尾N文字を残す文字列マスク |

実装: `tool/python/conversion_patterns.py`
テスト: `tool/python/tests/test_conversion_patterns.py`

## 入力契約の要点

- 104 float: ASCII の10進・指数表記のみ（`1_000`、前後の空白、ASCII 以外の数字は拒否）。`1e-400` のように 0 にアンダーフローする値は拒否せず `0.0` を返す（拒否は 107 unit のみ）。bool は `true`/`false`/`"1"`/`"0"`/整数 0・1 のみ。
- 105 date: `iso` は `YYYY-MM-DD` のみ（週日付・`YYYYMMDD` は `compact` を使う）。`compact` 出力は年を常に4桁にする。
- 107 unit: 結果が inf になる場合と、0 でない入力が 0 にアンダーフローする場合は拒否する。非正規化数（例: `1e-320` g→kg）は精度が落ちても受理する。
- 110 mask: 値の長さが `keep_last` 以下なら全文字を伏せる（末尾を見せても全体が露出しないように）。
  数え方は**コードポイント単位**（結合文字・絵文字の ZWJ 列は途中で切れうる）。`*` の数で**元の長さは分かる**。
- エラーは固定の文言（例: `invalid integer`、`invalid utf8 input`、`invalid iso date`、`invalid compact date`、CLI の `invalid json`）で返し、CPython や codec のメッセージは出さない。

## 完成度

**限定実装**。独立処理と異常系テストは存在するが、Flutter番号付き画面からの実行は未接続。
`/screen103`〜`/screen110`（106・108 を除く）は共通の `ConversionPatternLinks` に接続し、
実装・テスト・この文書への GitHub リンクを表示・コピーできる（Pages では deploy した commit に固定）。
Dartファイルはこの段階では削除していない。

106 CurrencyConvertはレート取得・時点・通貨精度の契約が必要なので、この単純変換グループには含めない。
108 TimeZoneは既存のタイムゾーン資産との整合を先に確認する。
102 SanitizeInputは「XSS/SQLを一つのsanitize関数で防ぐ」という誤った契約にしない。
100 AsyncValidation、111 DataEnrichは外部サービス契約が必要。
101 CrossField、112 DataClean、113 DataDeduplicateは別グループで機能契約を定義する。

次の段階では、実操作導線を追加するか、既存Dartがダミーであることを確認して責務移管・削減する。
