# T-030: OpenClaw→Claude Code タスク委任アーキテクチャ

## 概要

記事収集〜日本語翻訳の全工程を Claude Code headless モード（`claude -p`）に委任する。OpenClaw はオーケストレーター（cron スケジューリング + タスク管理）に徹し、実処理は Claude Code が担う。

## 背景

- MiniMax M2.5 は多言語混在（中国語・韓国語混入）の傾向があり、日本語翻訳品質に問題があった
- T-028 で翻訳品質ルールを強化、T-029 で Gemini への切り替えを検討していた
- Claude Code（Max 5x サブスクリプション）を活用すれば、追加コスト $0 で翻訳品質を根本的に改善可能
- 同時に Gemini API 導入（T-029）が不要になり、アーキテクチャが簡素化される

## 依存

- T-028（翻訳品質ルール強化）— 完了済み、ルールを SKILL.md に反映
- Claude Code CLI がサーバーにインストール・認証済み（v2.1.81）

## やること

### 1. 調査ドキュメント作成
- `docs/claude-code-channels調査.md` — Claude Code の外部連携機能（Channels, Headless CLI, Agent SDK, Hooks, MCP）を調査・文書化

### 2. ブリッジスクリプト作成
- `scripts/research-tech-news.sh` — OpenClaw から Claude Code を呼び出すラッパースクリプト
- `claude -p` でスキル定義を読み込み、記事収集〜翻訳を実行
- `--allowedTools` でツールを制限、ログ出力

### 3. スキル修正
- `.claude/skills/research-trend-news/SKILL.md` に翻訳品質ルールと実行方式を追加
- OpenClaw スキルとしては「research-tech-news.sh → run-daily.sh」の 2 ステップに

### 4. タスク管理更新
- T-029（Gemini）は Claude Code で代替として更新
- 開発タスク.md に T-030 追加

### 5. CLAUDE.md 更新
- アーキテクチャセクションに Claude Code 委任パイプラインを反映

## 改訂パイプライン

```
[JST 9:15] OpenClaw cron
    ↓
[OpenClaw] スキル実行
    ↓
[bash] scripts/research-tech-news.sh
    ↓
[Claude Code] claude -p（記事収集 → フィルタリング → 翻訳 → 出力）
    ↓
[bash] scripts/run-daily.sh（git add → commit → push）
    ↓
[Cloudflare Pages] 自動デプロイ
```

## 完了条件

- `docs/claude-code-channels調査.md` が作成されている
- `scripts/research-tech-news.sh` が作成され、手動実行で記事が生成される
- SKILL.md に翻訳品質ルールと実行方式が記載されている
- 生成記事に中国語・韓国語・ロシア語が混入していない
- T-029 が「Claude Code で代替」として更新されている
- CLAUDE.md のアーキテクチャが更新されている

## コスト影響

- 追加コスト: $0（Max 5x サブスクリプションに含まれる）
- MiniMax 使用量: ニュース収集タスク分が不要に
- Gemini API キー取得が不要

**ステータス**: 🔧 実装中（2026-03-22）
