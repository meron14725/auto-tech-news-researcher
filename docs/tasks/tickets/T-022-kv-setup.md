# T-022: Cloudflare KV ネームスペース作成

## 概要
フィードバックデータを保存するための Cloudflare KV ネームスペースを作成し、Pages プロジェクトにバインドする。

## やること
- `ARTICLE_FEEDBACK` ネームスペースを作成（`wrangler kv namespace create`）
- Pages プロジェクトへのバインド設定
- VPS 用の API トークン発行（KV 読み書きスコープ）
- KV スキーマ: キー `{YYYY-MM-DD}::{url}` → 値 `{"rating","timestamp","source","interest_score"}`

## 依存
- T-016（Cloudflare Pages デプロイ）

## 完了条件
- KV ネームスペースが存在し Pages にバインドされている
- VPS 用 API トークンが発行されている
