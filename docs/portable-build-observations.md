# Python／Nodeを毎回の実ビルドに同席させる

通常の入口はPython／Nodeとし、Flutter／Xcode／Androidは、残るネイティブ機能を
実測する際の参照実装として段階的に使う。新しい機能は、可能ならPython stdlibと
Node標準API、既存vendorを優先する。依存を増やす場合は所有元・固定版・ライセンス・
更新方法を明示し、各アプリに同じコピーやテストランナーを増やさない。

## 今回接続する範囲

`.github/actions/build-companions`が、既存のFlutterビルドを1回実行してから、
**同じrunner上**のPythonとNodeで固定9条件＋seed付き4条件を毎回測定する。ビルド失敗・タイムアウト
でも両者の測定を試し、失敗したビルドを合格に置き換えない。子プロセスは2並列・
各30秒で上限を設ける。ネイティブ負例の採取でも同じ実行関数を再利用する。

- pinned／latest Web、Pages、diagnostics、refactor、通常のportable E2E。
- 既存のiOS release／simulatorビルド。iOSを起動する変更範囲は拡大しない。
- Docker内Webビルド。Python／Nodeは同じイメージ内で実行する。
- one-shotのDart／Kotlin／Swift採取ジョブは、引き続き実ビルド＋両companionを実行する。

Webの変更ごとに6 OSのビルドを増設する仕組みではない。現在ないmacOS／Windows／
Linuxネイティブビルドジョブを検証済みとはしない。CLIの`--target`はビルド対象で、
実行hostのOS／architectureと別フィールドに保存する。

```sh
python -S python/capture_build_companions.py --target web --output build/build-companions/local --build-command '["flutter","build","web"]' --probe-tools .build-probe-tools
```

`.build-probe-tools`はactionが完全SHAで取得する既存xprobeのCI用checkout。
実ビルドのstdout／stderr原文・終了コード、共有入力・実測値・期待値、ソースの
sha256とスナップショット、Git／Flutter doctor／各SDKの測定、host情報、run IDを残す。
`acceptance.xml`と意図した失敗を含む`observed-failures.xml`は別に保存する。
`build-companions-*` artifactは90日保持。既存の必須JUnit identity計画は変更しない。

Dockerイメージの作成時は追加のネットワーク取得なしでJSONと原文ログを保存する
（`junit_written:false`）。起動時に既存の`e2e/test-results` artifactへコピーする。
Dockerレイヤーが再利用された場合、そのreceiptは**過去のビルド時の測定**であり、
新しいrunで実行したとは読み替えない。失敗したDocker image buildの内容はGitHubの
buildログに残るが、完成していないイメージからreceiptを取り出したとは主張しない。

## 表示差・操作差の収集

全ページ巡回は既存の`python/playwright.py pages`とbrowser-test-kitのinventory／
pointer／seed付き探索を再利用する。ページごとの座標・操作・スクリーンショットに、
viewport、device scale、screen／window／document寸法、visual viewport、CSS safe area、
タッチ・hover、言語・timezone、配色・動きの設定を併記する。

ブラウザの報告値とrunner OSを混ぜない。`runtime.execution_kind:web-browser`、
`native_os_verified:false`を明示する。iPhone／Android等のdevice設定はブラウザの
表示条件で、実機やネイティブOSの証跡ではない。

合格条件は操作の意味・出力とレイアウトの成立。OSや画面サイズで座標・外観が変わる
こと自体を失敗にしない。既存の`check_web_observations.py --baseline`は、同じ表示条件の
幾何回帰を厳密に見る任意モードなので、異なるOSプロファイル同士の合格判定に使わない。

## 段階的に置き換える境界

1. 全ルートの入力・操作前後・出力・失敗と、そのときの表示条件を収集する。
2. iOS／Android／macOS／Windows／Linuxの**実測がある条件だけ**対応プロファイルへ登録する。
   未測定の権限、IME、クリップボード、ウィンドウ、native pluginは未確認のまま残す。
3. Python／Nodeの再実装に同じ入力を渡し、意味・操作完了・レイアウト成立を比較する。
4. 確認した範囲からWebで切り替え・再現し、重いビルドの頻度を減らす。

現在のcompanion 13条件は言語プリミティブで、全画面の再実装ではない。保存ログだけで
現行コードが動いたとはしない。Dart／Kotlin／Swiftの可逆変換や完全代替も、この証跡だけ
で達成したとはしない。既存JUnit identityは失敗の入口として使い、再現には必ず入力・
ソース／環境情報・原文ログを対で使う。画像／Office等はIronmate、ブラウザ実行は
browser-test-kit、Web資料の構造化はBlueProbe、共有入出力・失敗の再実測はxprobeの
既存責務を優先する。
