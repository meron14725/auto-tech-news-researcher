# T-006: Zenn 記事取得機能

**ステータス**: ✅ 完了（2026-03-15）

## 概要
Zenn の RSS フィードからトレンド記事を取得する処理をスキル内に実装する。

## やること
- `https://zenn.dev/feed` から RSS を取得
- XML をパースして記事情報（タイトル、URL、概要）を抽出
- 取得した記事データを共通フォーマットに変換

## 参考
- RSS: `https://zenn.dev/feed`
- 認証不要

## 完了条件
- curl で Zenn RSS フィードを取得できる
- RSS の XML から記事情報が正しく抽出される

## 完了メモ
- SKILL.md に Zenn RSS 取得手順を定義
- RSS フィード動作確認済み（「Zennのトレンド」フィードからXML取得成功）
- XML パースは Claude Code が実行時に Bash で処理
