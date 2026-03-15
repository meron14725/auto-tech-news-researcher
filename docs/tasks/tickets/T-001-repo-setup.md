# T-001: GitHub リポジトリ初期セットアップ

**ステータス**: ✅ 完了（2026-03-15）

## 概要
プロジェクトのディレクトリ構成を整備し、基本的な設定ファイルを配置する。

## やること
- リポジトリのディレクトリ構成を作成（`content/posts/`, `data/`, `scripts/`, `layouts/`, `.claude/skills/`）
- `.gitignore` の設定（Hugo ビルド成果物、OS固有ファイル等）
- `CLAUDE.md` の配置（プロジェクト指示書）
- `data/processed_urls.json` の初期ファイル作成（空配列）

## 完了条件
- 必要なディレクトリがすべて存在する
- `.gitignore` が適切に設定されている
- `CLAUDE.md` がプロジェクトルートに配置されている

## 完了メモ
- ディレクトリ構成を作成し、空ディレクトリには `.gitkeep` を配置
- `.gitignore` に Hugo ビルド成果物、OS ファイル、エディタファイル、環境変数ファイルを設定
- `CLAUDE.md` は `.claude/CLAUDE.md` に配置（Claude Code が自動認識する標準パス）
- `data/processed_urls.json` を空配列 `[]` で初期化
