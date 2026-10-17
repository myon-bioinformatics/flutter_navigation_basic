# Flutter CIで一度採取し、Python／Nodeもその場で実測する

日常のPRとは分けて、CIに既に用意するFlutter／Android／Xcodeの環境で実測する。
採取済みのログを読むだけでPython／Nodeの実装が合格したことにはしない。

## 最初の採取範囲

共通入力は配列長`0, 3, -1`。非負なら実際に構築した配列の長さを出し、負なら実際の
言語エラーを逃がして診断を残す。各実装が独立に期待条件を満たすことを検査する。

| CIの言語 | 最初に確認するアプリの正常ビルド | その環境での実測 |
|---|---|---|
| Dart / Ubuntu | `flutter build web --debug` | Flutter同梱Dart VMで`List.filled` |
| Kotlin / Ubuntu | `flutter build apk --debug`（arm64のみ） | アプリのGradle/JUnitで`IntArray` |
| Swift / macOS | `flutter build ios --simulator --debug --no-codesign` | Xcodeの`swiftc`でコンパイルした標準配列 |

**各ジョブでPythonとNodeも3入力を実行する。** Pythonは明示した非負長の仕様を
独立のガードで実装し、Nodeは`new Array(count)`を使う。共通の失敗分類は
`invalid_array_length`、元の終了コード・例外ログは変換せず保持する。
正常結果はログに書かれた実測値から読む。Kotlinの成功もJUnitの印字値を解析し、
期待値の丸写しで補完しない。負例のエラー種別や必要な印字が欠ければ失敗にする。

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

ワークフロー内の入口:

```sh
python -S python/capture_native_errors.py --language dart --output build/native-error-corpus/dart --probe-tools .native-probe-tools
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
- `source-*`: 実際に使った5言語の小さなプローブ。
- `kotlin-original-junit.xml`: Gradleが出したJUnit原文（Kotlinジョブ）。
- `acceptance.xml`: 正常例・意図した負例・Python／Nodeの期待条件が成立したか。
- `observed-failures.xml`: 実際のプロセス失敗を含むJUnit。故意の失敗例として保存する。

通常の必須JUnitには`acceptance.xml`を使う。意図した失敗のXMLを通常の失敗集計に
混ぜて常時赤くしない。xprobeの既存identity importerは元入力を復元しないので、
JUnitとJSON／ログを対で残す。

SDKなしの検査は`python -m pytest python/tests/test_capture_native_errors.py`。
これはPython／Nodeの実測と解析・制御の回帰検査であり、3ネイティブ言語の代用実測ではない。
