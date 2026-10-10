# Pattern 136: Isolate

## 実装
- `view.dart` は共通の `NativeParallelPatternExample` を表示する薄いView。
- 実計算は `lib/core/data_processing/native_parallel_pattern_example.dart` で行う。
- ネイティブでは Isolate.run、Webでは明示的な同期フォールバック。
- 100ms待機して固定の成功文言を返す旧Controller・Service・Modelは削除済み。

## 検証
`test/features/data_processing_patterns/native_parallel_routes_test.dart` にて実計算結果と非同期完了を検証する。ネイティブ並列性そのものはプラットフォーム別の追加検証が必要。
