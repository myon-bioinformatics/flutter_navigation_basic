# Pattern 155: GetxWorker

ever/once/debounce/interval Workers 実装。

## 現在の実装
- `view.dart` はGetX非依存の共通 `NativeStateCatalogueExample` を使用する。
- 加算／リセットと `ValueNotifier` の更新・破棄は実動作する。
- **元のGetX固有機能は移植していない**（Bindings、Workers、Service永続化、GetxControllerのライフサイクル等）。
- 古いController／Model／Serviceは100ms待つダミー実装だったため削除。
- Flutterテスト: `test/features/data_processing_patterns/native_state_catalogue_test.dart`
- 詳細: `docs/getx-retirement-151-156.md`
