# T-026: スキル改善スクリプト

## 概要
2日ごとに OpenClaw cron で実行し、ユーザーフィードバックをもとに SKILL.md を改善する。

## 依存
- T-021（スキル評価フレームワーク）
- T-025（フィードバック取得スクリプト）

## やること

### 1. `scripts/run-improve.sh` 修正
- git pull
- fetch-feedback.sh 実行
- feedback.json の件数チェック（5件未満ならスキップ）
- （OpenClaw エージェントが SKILL.md を分析・改善）
- 安全策: SKILL.md 以外のファイル変更があれば abort
- git add → commit → push

### 2. OpenClaw cron 登録
```bash
openclaw cron add \
  --name "skill-improvement" \
  --cron "0 23 */2 * *" \
  --tz "Asia/Tokyo" \
  --session isolated \
  --message "scripts/fetch-feedback.sh を実行してフィードバックを取得し、data/feedback.json を分析して research-trend-news スキルの SKILL.md を改善してください。改善後、scripts/run-improve.sh を実行してください。"
```

## 完了条件
- 2日ごとにフィードバックを分析し SKILL.md が改善される
- SKILL.md 以外の変更を検知して abort する安全策が動作する
- 日次パイプラインと干渉しない
