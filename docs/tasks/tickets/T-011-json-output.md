# T-011: 記事JSON出力機能

## 概要
フィルタリング・要約が完了した記事を `content/posts/YYYY-MM-DD.json` として出力する。

## やること
- 所定の JSON スキーマに従った出力ファイルの生成
- ファイル名を実行日の日付（`YYYY-MM-DD.json`）にする
- 同日に複数回実行された場合の上書き or マージ方針の決定
- JSON の整形（pretty print）

## JSON スキーマ
```json
{
  "date": "YYYY-MM-DD",
  "articles": [{ "title", "original_title", "source", "url", "summary", "tags", "interest_score" }]
}
```

## 完了条件
- `content/posts/YYYY-MM-DD.json` が正しいスキーマで出力される
- JSON が valid である（パースエラーがない）
