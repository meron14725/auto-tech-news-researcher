# T-012: デイリー実行スクリプト作成

**ステータス**: ✅ 完了（2026-03-15）

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

## 完了メモ
- `scripts/run-daily.sh` を作成（実行権限付与済み）
- `set -euo pipefail` で厳格なエラーハンドリング
- 各ステップ（git pull, claude -p, git push）でエラー検知 → 即時終了
- 変更がない場合（記事0件）はコミット・プッシュをスキップ
- ログは `logs/daily-YYYY-MM-DD.log` に出力（logs/ は .gitignore 済み）
- `--allowedTools 'Bash(curl *),Bash(date *),Read,Write'` で最小限のツール許可
