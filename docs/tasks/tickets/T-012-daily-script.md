# T-012: デイリー実行スクリプト作成

## 概要
毎日の自動実行を担う `scripts/run-daily.sh` を作成する。git pull → Claude 実行 → git push の一連の流れを自動化する。

## やること
- `scripts/run-daily.sh` の作成
- 処理フロー:
  1. `cd` でプロジェクトディレクトリに移動
  2. `git pull origin main` で最新コード取得
  3. `claude -p` でスキル実行（`--allowedTools`, `--max-turns 20`）
  4. `git add content/posts/ data/processed_urls.json`
  5. `git commit -m "Add articles for YYYY-MM-DD"`
  6. `git push origin main`
- エラー時の処理（スキル実行失敗時は push しない等）
- ログ出力（`logs/` ディレクトリに日付付きログ）

## 完了条件
- スクリプトを手動実行して一連のフローが動作する
- エラー時に不正な commit/push が行われない
- 実行ログが残る
