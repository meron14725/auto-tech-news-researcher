# T-017: Qiita 記事取得機能

## 概要
Qiita の RSS フィードからトレンド記事を取得する処理をスキルに追加する（Phase 2）。

## やること
- `https://qiita.com/popular-items/feed.atom` から Atom フィードを取得
- XML をパースして記事情報を抽出
- 取得した記事データを共通フォーマットに変換
- 既存の Zenn RSS 取得処理と同様のパターンで実装

## 参考
- RSS: `https://qiita.com/popular-items/feed.atom`
- 認証不要

## 完了条件
- Qiita の人気記事が取得・処理される
- 既存の3ソースと合わせて正常動作する
