# T-025: フィードバック取得・変換スクリプト

## 概要
Cloudflare KV から評価データを取得し、skill-creator が読み取れる `data/feedback.json` に変換するスクリプトを作成する。

## やること
- `scripts/fetch-feedback.sh` を作成
- Cloudflare KV REST API で直近2日分のフィードバックを取得
- `data/feedback.json` に変換（ソース別・スコア別の集計サマリ付き）
- 環境変数: `CF_ACCOUNT_ID`, `CF_KV_NAMESPACE_ID`, `CF_API_TOKEN`
- フィードバックが0件の場合のハンドリング

## 依存
- T-022（KV ネームスペース）

## 完了条件
- スクリプトが KV から正しくデータを取得できる
- `data/feedback.json` が仕様通りのフォーマットで出力される
- フィードバック0件でもエラーにならない
