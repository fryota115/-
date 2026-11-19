# 日々の手帖

iPhoneのSafariからホーム画面に追加して使える [日々の手帖 Web版](https://hibi-techou-calendar.steeplarch8.chatgpt.site) を非公開で配信しています。[Web版の利用・開発手順](web/README.md)

iOS 17以降のiPhone向け個人用カレンダーです。Phase 1では、モック予定を使って月・週・日の見た目と日付移動を確認できます。システムのカレンダーやリマインダーへのアクセス許可は求めません。

## 起動

MacのXcode 15以降で `PaperCalendar.xcodeproj` を開き、`PaperCalendar` スキームとiOS 17以降のiPhoneシミュレータを選択して実行します。実機で起動する場合は、ターゲットの「Signing & Capabilities」で自分のチームを選択します。初期表示は月間カレンダーです。

- [SPEC.md](SPEC.md) に画面仕様と必須29機能の進捗を記載しています。
- [AGENTS.md](AGENTS.md) に開発ルールを記載しています。
- [PLAN.md](PLAN.md) に構成とPhase 1〜7の実装計画を記載しています。

## Phase 1の検証

- WSLのUbuntuでSwift 6.4.2を使い、`CalendarCore` のビルドと単体テスト10件に成功しました。`CalendarViewModel` の型チェックと、Swiftコンパイラによるアプリソースの構文解析も通過しました。
- Xcodeターゲットのソース参照、ローカルパッケージ、共有スキーム、iOS 17／iPhone向け設定を静的に確認しました。
- iOSアプリのコンパイル、画面表示、実機・シミュレータでの操作は未確認です。作業環境のWindowsではXcodeとiOSシミュレータを実行できません。

Macでシミュレータ用にビルドし、日付計算・配置の単体テストを実行するコマンドです。単体テストはうるう年、月・年境界、タイムゾーン、夏時間、午前0時終了、複数日予定の帯、重なる予定のタイムラインを対象にしています。

```sh
xcodebuild -project PaperCalendar.xcodeproj -scheme PaperCalendar \
  -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
swift test --package-path CalendarCore
```

### シミュレータ確認項目

1. 月表示で日付を選び、「週」「日」に切り替えて選択日が引き継がれることを確認する。各表示で左右スワイプと矢印を試し、日・週・月のそれぞれの単位で移動することを確認する。縦スクロール中にページが切り替わらないことも確認する。
2. 過去のページに移動して現在のカレンダータブを再タップし、今日へ戻ることを確認する。今日の下線と選択日の背景を確認する。
3. 上部の日付からうるう日を指定し、移動とキャンセルの両方を試す。「その他」でも「今日へ」と「日付を指定」が使えることを確認する。
4. 今月中旬の複数日予定、月末から翌月に続く帯、予定が重なった場合の日表示、日付下の `+件数`、予定詳細を確認する。「＋」と「タスク」では準備中の案内が開く。
5. 「その他」で週の開始曜日と予定文字サイズを変更し、再起動後にも設定が維持されることを確認する。小型・大型iPhoneの縦画面、Dynamic Typeの最大サイズとVoiceOverで試す。
