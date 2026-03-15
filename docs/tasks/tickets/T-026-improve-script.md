# T-026: スキル改善スクリプト (run-improve.sh)

## 概要
2日ごとに cron で実行し、ユーザーフィードバックをもとに SKILL.md を改善するスクリプトを作成する。

## やること
- `scripts/run-improve.sh` を作成
- 処理フロー: git pull → fetch-feedback.sh → 件数チェック → claude -p で改善 → commit & push
- 最低5件のフィードバックがなければスキップ
- 安全策: SKILL.md 以外のファイルが変更されていたら abort
- ログ出力: `logs/improve-YYYY-MM-DD.log`

## cron スケジュール
```
0 23 */2 * * /path/to/scripts/run-improve.sh >> /path/to/logs/improve-cron.log 2>&1
```

## 依存
- T-021（skill-creator 再構築）
- T-025（フィードバック取得スクリプト）

## 完了条件
- フィードバックを元に SKILL.md が改善される
- SKILL.md 以外の変更を検知して abort する安全策が動作する
- 日次パイプライン（run-daily.sh）と干渉しない
