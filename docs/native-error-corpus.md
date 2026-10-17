# Flutter CIで一度採取し、Python／Nodeもその場で実測する

日常のPRとは分けて、CIに既に用意するFlutter／Android／Xcodeの環境で実測する。
採取済みのログを読むだけでPython／Nodeの実装が合格したことにはしない。

## 最初の一巡: 正常2条件＋負例7種類

`tools/native_error_corpus/cases.json`に共有入力・期待結果・言語ごとの診断条件を明示する。
期待するエラーは、負の配列長、範囲外アクセス、null、型キャスト、不正な整数、不正なJSON、
整数のゼロ除算。配列長0・3の正常例も実行する。

| CIの言語 | 正常アプリビルドの基準 | 新しく実行するプローブ |
|---|---|---|
| Dart / Ubuntu | Flutter Web debug | Flutter同梱Dart VMで9条件 |
| Kotlin / Ubuntu | Flutter Android arm64 debug | アプリのGradle/JUnitで8条件＋JSON未観測1件 |
| Swift / macOS | Flutter iOS simulator debug / no-codesign | XcodeでコンパイルしたSwift CLIで9条件 |

**各ジョブでPythonとNodeも9条件ずつ新しく実行する。** JSのboundsはDataView、整数解析・
ゼロ除算はBigIntを使う。JS/Pythonの型キャスト等の共通仕様は独立の明示ガードで実装する。
各言語の元の例外・終了コードを同じものとして捏造せず、共通分類と原文を並べて残す。

Kotlinの現在のJVMテスト依存には実体のJSONパーサがない。Androidのmockによる別の失敗を
JSON解析エラーと扱わず、JUnitの明示skipと`context.unobserved`に残す。その他のskipや
予想外の例外、成功結果・診断の欠落は合格にしない。Kotlinの正常値も実際の印字を解析する。

これは言語プリミティブの最初の負例コーパス。Flutterのビュー、Androidデバイスや
iOSシミュレータ上のアプリ操作／OS権限を検証したという意味ではない。
Dart VMとWebビルド出力、JVMとAndroid実機、macOS Swift CLIとiOSアプリを区別する。
追加のアプリ固有エラーはこの分類で済ませず、別の入力・期待条件・実行環境を持たせる。

## 起動

`.github/workflows/native-error-corpus.yml`は`push`や通常のPR更新で重い採取をしない。

- 同一リポジトリのPRに`capture-native-errors`ラベルを**追加したイベント**で1回起動する。
  その後のpushでは再実行しない。新しいheadで採り直すならラベルを外して再追加する。
- main導入後はActionsの`workflow_dispatch`でも明示実行できる。
- 3言語は独立ジョブで並行し、片方の失敗でも他方の証跡を残す。
- 元のアプリコードは変更しない。Kotlinの専用テストだけ一時配置し、`finally`で除去する。
  Swiftの故意のトラップではcore dumpを作らない。
- SDKや正常ビルドの失敗を、意図した言語エラーとして合格にしない。
  ネイティブの基準ビルドに失敗してもPython／Nodeは実測して証跡を残す。

## 前回の正常ビルドの再利用

前回の成功run `39033656033`の言語別artifactをread-onlyの`actions: read`で取得する。
正常build成功、同じ言語・ビルドコマンド、Flutter/engine/Dartのrevision、Xcode/Swiftまたは
JDKの実測版、対象の追跡済みソース・ロック・設定・assetが一致する場合だけ再利用する。
Git比較にはworking treeの変更も含め、過去結果を今回実行したように扱わない。

一致した場合は`healthy_build_executed_current_run: false`と元run/SHAを残す。
証跡が欠落・失効している、ツールチェーンや入力が違う、比較できない場合は実ビルドへ戻す。
前回の小さな配列長プローブの成功を、今回の新しいエラープローブの実行として流用しない。
90日でartifactが失効した後も、欠落を合格に置き換えず実ビルドを行う。

```sh
python -S python/capture_native_errors.py --language dart --output build/native-error-corpus/dart --probe-tools .native-probe-tools --baseline-receipt .native-baseline/receipt.json
```

`.native-probe-tools`はworkflowの完全SHAに固定したxprobe checkout。
新規vendorコピーではなく採取用CIツールとして既存`write_junit`を再利用する。
採取はxprobe PR #16の固定リビジョンを使うため、そのコードと対象headのレビューが必要。
ツール本体のmerge後に固定SHAを更新する場合は、その更新も明示してレビューする。

## 保存物と合否

各言語のartifactに次を保存する（90日保持）。永続的な研究資料に採用するものは、
元artifactのrun ID／SHAとハッシュを保って別途リポジトリに採用する。

- `receipt.json`: 共有入力、実測値、期待値、元ログ、ソースハッシュ、Git SHA、
  Flutter/Dart/Node/JDK/Xcode/Gradleの実測情報とメタ情報取得の失敗。
- `*.stdout.log`, `*.stderr.log`: 元のバイト列。JSONにはUTF-8置換表示とバイトハッシュも保存。
- `source-*`: 実際に使った5言語の小さなプローブと9条件の入力仕様。
- `kotlin-original-junit.xml`: Gradleが出したJUnit原文（Kotlinジョブ）。
- `acceptance.xml`: 正常例・意図した負例・Python／Nodeの期待条件が成立したか。
- `observed-failures.xml`: 実際のプロセス失敗を含むJUnit。故意の失敗例として保存する。

通常の必須JUnitには`acceptance.xml`を使う。意図した失敗のXMLを通常の失敗集計に
混ぜて常時赤くしない。xprobeの既存identity importerは元入力を復元しないので、
JUnitとJSON／ログを対で残す。

SDKなしの検査は`python -m pytest python/tests/test_capture_native_errors.py`。
これはPython／Nodeの実測と解析・制御の回帰検査であり、3ネイティブ言語の代用実測ではない。
