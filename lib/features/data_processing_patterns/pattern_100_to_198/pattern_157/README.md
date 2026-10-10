# Pattern 157: ProviderBasic

Provider パターンによる状態管理 (擬似実装)。

`provider`パッケージは追加せず、Flutter標準の`InheritedWidget`を使った
provider-like状態伝播を`lib/core/data_processing/inherited_catalogue_example.dart`
で実装する。Providerライブラリそのものの互換実装ではない。

検証: `test/features/data_processing_patterns/inherited_catalogue_test.dart`
旧GetX Controller・成功メッセージModel・100msダミーServiceは撤去。
