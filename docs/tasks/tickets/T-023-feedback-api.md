# T-023: フィードバック API 実装

## 概要
記事の評価を受け取る Cloudflare Pages Function を実装する。

## やること
- `functions/api/feedback.js` を作成
- POST で `{date, url, rating, source, interest_score}` を受け取り KV に保存
- バリデーション（日付形式、URL形式、rating は "good"/"bad" のみ）
- CORS ヘッダー設定
- レートリミット（IP + URL 単位、60秒 TTL の KV キーで制御）

## 依存
- T-022（KV ネームスペース）

## 完了条件
- `POST /api/feedback` で rating が KV に保存される
- 不正リクエストに 400 を返す
- 重複投票は上書き（last vote wins）
