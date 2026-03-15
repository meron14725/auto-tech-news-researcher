# T-016: Cloudflare Pages デプロイ設定

## 概要
GitHub リポジトリと Cloudflare Pages を連携し、main ブランチへの push をトリガーに Hugo ビルド → 自動デプロイする。

## やること
- Cloudflare アカウントの作成（未作成の場合）
- Cloudflare Pages プロジェクトの作成
- GitHub リポジトリとの連携設定
- ビルド設定:
  - ビルドコマンド: `hugo`
  - 出力ディレクトリ: `public`
  - Hugo バージョンの指定（環境変数 `HUGO_VERSION`）
- カスタムドメインの設定（任意）
- テストデプロイの実施

## 完了条件
- main に push すると自動でビルド＆デプロイが実行される
- デプロイされたサイトにブラウザからアクセスできる
- Hugo ビルドがエラーなく完了する
