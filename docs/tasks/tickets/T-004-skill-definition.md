# T-004: Claude Code スキル定義

**ステータス**: ✅ 完了（2026-03-15）

## 概要
Claude Code CLI のスキル機能を使い、ニュース収集・要約の処理を `.claude/skills/research-trend-news/SKILL.md` として定義する。

## やること
- `SKILL.md` の作成（スキルの目的、手順、出力形式を記述）
- スキル内で使用するツール（`Bash`, `Read`, `Write` 等）の定義
- 記事取得 → フィルタリング → 要約 → JSON出力 の一連のフローを指示
- `--allowedTools` で許可するツールのリストを決定

## 完了条件
- `claude -p "/research-trend-news スキルを実行して"` で処理が起動する
- スキルが所定のJSON形式で記事を出力する
- `--max-turns 20` 以内で処理が完了する

## 完了メモ
- `.claude/skills/research-trend-news/SKILL.md` を作成
- 処理フロー: 準備 → 記事取得（HN/Zenn/dev.to） → フィルタリング（score>=7） → 日本語要約 → MD出力
- 使用ツール: Bash（curl）、Read、Write の3つ
- エラー時の部分継続、重複排除、最大15件の制限を定義
- 実行テストは T-005〜T-011 の各機能実装後に実施
