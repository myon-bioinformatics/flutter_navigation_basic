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

## 完成度

**限定実装**。独立処理と異常系テストは存在するが、Flutter番号付き画面からの実行は未接続。
Dartファイルはこの段階では削除していない。

106 CurrencyConvertはレート取得・時点・通貨精度の契約が必要なので、この単純変換グループには含めない。
108 TimeZoneは既存のタイムゾーン資産との整合を先に確認する。
102 SanitizeInputは「XSS/SQLを一つのsanitize関数で防ぐ」という誤った契約にしない。
100 AsyncValidation、111 DataEnrichは外部サービス契約が必要。
101 CrossField、112 DataClean、113 DataDeduplicateは別グループで機能契約を定義する。

次の段階では、実操作導線を追加するか、既存Dartがダミーであることを確認して責務移管・削減する。
