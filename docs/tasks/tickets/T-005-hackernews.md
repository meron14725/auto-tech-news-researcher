# T-005: Hacker News 記事取得機能

**ステータス**: ✅ 完了（2026-03-15）

## 概要
Hacker News の Firebase API を使って、トレンド記事を取得する処理をスキル内に実装する。

## やること
- `/v0/topstories.json` からトップ記事のID一覧を取得
- 各記事の詳細を `/v0/item/{id}.json` から取得
- スコア（ポイント数）やコメント数をもとに上位記事を選別
- 取得した記事データを共通フォーマットに変換

## 参考
- API: `https://hacker-news.firebaseio.com/v0/`
- 認証不要、レート制限なし

## 完了条件
- curl でHN APIからトップ記事を取得できる
- 取得結果が共通の記事フォーマットに変換される

## 完了メモ
- SKILL.md に HN Firebase API の取得手順を定義（topstories → item 詳細の2段階）
- 上位30件を取得対象として指定
- API 動作確認済み（500件のストーリーID取得、個別記事の title/score/url 取得成功）
