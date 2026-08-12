# 案B: API連携パターン — 実装ガイド

## ディレクトリ構造

```
features/api_patterns/
├── pattern_001_to_099/
│   ├── pattern_001/ {view,controller,service,model,README}.dart
│   └── ...
├── pattern_100_to_198/
│   └── ...
└── docs/
```

## 実装の基本原則

1. **単一責任** — 各ファイルは1つの責務のみ
2. **依存性の方向** — view → controller → service → model
3. **標準ライブラリ優先** — dart:convert / dart:async / dart:io
4. **テスト可能な設計** — 依存性注入を活用
5. **JSON/YAML外出し** — assets/config/ に設定を外出し

## テスト実行
```bash
flutter test
flutter test test/features/{cat_key}/
```

## HTTP実装例 (dart:io 標準ライブラリ)

Pattern 001〜002 に完全な HTTP 実装を提供しています。
他のパターンも同一の構造で実装できます。

### GET リクエスト (Pattern 001 参照)
```dart
import 'dart:convert';
import 'dart:io';

final client = HttpClient();
final request = await client.getUrl(Uri.parse(url));
final response = await request.close();
final body = await response.transform(utf8.decoder).join();
final json = jsonDecode(body);
client.close();
```

### POST リクエスト (Pattern 002 参照)
```dart
final request = await client.postUrl(Uri.parse(url));
request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
request.write(jsonEncode(payload));
final response = await request.close();
```

### PUT / PATCH / DELETE
```dart
// PUT
final request = await client.putUrl(Uri.parse(url));
// PATCH
final request = await client.patchUrl(Uri.parse(url));
// DELETE
final request = await client.deleteUrl(Uri.parse(url));
```

> **標準ライブラリ方針**: 外部 HTTP パッケージ (dio 等) を使わず
> `dart:io` の `HttpClient` と `dart:convert` の `jsonDecode/jsonEncode` で実装します。
