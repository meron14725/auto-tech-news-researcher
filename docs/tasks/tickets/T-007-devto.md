# T-007: dev.to 記事取得機能

**ステータス**: ✅ 完了（2026-03-15）

## 概要
dev.to の REST API を使って、トレンド記事を取得する処理をスキル内に実装する。

## やること
- `/api/articles?top=1` 等で直近のトップ記事を取得
- 記事のタイトル、URL、タグ、リアクション数を抽出
- 取得した記事データを共通フォーマットに変換

## 参考
- API: `https://dev.to/api/articles`
- 認証不要（GET リクエスト）

## 完了条件
- curl で dev.to API からトップ記事を取得できる
- 取得結果が共通の記事フォーマットに変換される

## 完了メモ
- SKILL.md に dev.to REST API 取得手順を定義（`per_page=30&top=1`）
- API 動作確認済み（JSON レスポンスで title/url/tags/reactions_count 取得成功）
