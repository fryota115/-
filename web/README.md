# 日々の手帖 Web版

Safariからホーム画面に追加して使う、個人用のカレンダーです。ブラウザのIndexedDBに予定・タスク・表示設定を保存します。予定の日時は、入力した現地の日付と時刻を保持します。

## 利用できる機能

- 月・週・日表示、左右スワイプ、今日と指定日への移動。月表示に複数日予定の帯を表示します。
- 予定の追加・編集・複製・個別削除と、タイトル・場所・メモの検索。終了日を指定した終日予定も登録できます。
- ローカルタスク、期限の設定、完了切替。期限付きの未完了タスクはカレンダーにも表示します。
- カレンダーの色分けと表示設定、曜日の開始を月曜・日曜から選択、予定文字サイズの設定。
- 最初にサンプル予定が入ります。「その他」または「設定」からサンプルだけを消せます。編集したサンプルは利用者の予定として残ります。

端末をまたぐ同期、標準カレンダー・リマインダーとの連携、繰り返し、通知、ウィジェットは対象外です。

## iPhoneに追加

配信URLをiPhoneのSafariで開き、共有メニューから「ホーム画面に追加」を選びます。「ウェブアプリとして開く」が表示される場合はオンにします。その後はホーム画面のアイコンを入口に使います。初回は通信できる場所で開いてください。

静的ファイルをHTTPSで配信します。Service Workerが画面用ファイルをキャッシュした後はオフラインで開けます。予定とタスクは登録したWebアプリ内に保存されるため、ほかの端末や別の配信URLとは共有されません。

## GitHub Pagesで配信

リポジトリのルートにある `hibi-techou-github-pages.zip` を展開します。GitHub Freeの場合は新規の公開リポジトリを作成し、展開したファイルを `.nojekyll` と一緒に `main` のルートにアップロードします。`index.html` がリポジトリの最上位にあることを確認してください。

リポジトリの **Settings → Pages** で **Deploy from a branch** を選び、**main / (root)** を指定して保存します。公開後に **Visit site** で表示されるHTTPSのURLをSafariで開き、ホーム画面に追加します。 [GitHub Pagesの公式手順](https://docs.github.com/en/pages/getting-started-with-github-pages/configuring-a-publishing-source-for-your-github-pages-site)

## Windowsで確認

このフォルダを含むリポジトリのルートで実行します。

```powershell
python -m http.server 8078 --bind 127.0.0.1 --directory web/dist
```

同じPCのブラウザで `http://127.0.0.1:8078/` を開きます。Node.jsで日付と予定配置の単体テストを実行できます。

```sh
node --test web/test/calendar.test.mjs
```

画面ファイルを更新する際は `dist/service-worker.js` のキャッシュ番号も更新します。
