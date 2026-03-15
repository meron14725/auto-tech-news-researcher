# T-004: Claude Code スキル定義

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
