# T-012: デイリー実行スクリプト修正

**ステータス**: ✅ 完了（2026-03-21）

## 概要
`scripts/run-daily.sh` から `claude -p` による AI 実行を削除し、git 操作のみのラッパーに変更する。OpenClaw エージェントがスキル実行後にこのスクリプトを呼び出す。

## やること
- `claude -p` の呼び出しを削除
- git pull → 変更チェック → git add/commit/push のみ残す
- コメントを OpenClaw 前提に更新

## 完了条件
- スクリプトに AI 実行の処理が含まれていない
- git 操作のみで正常に動作する

## 完了メモ
- `claude -p` によるスキル実行（旧 Step 3）を完全に削除
- 変更チェックを改善: `git diff` に加えて未追跡ファイル（`git ls-files --others`）もチェックするように修正
- OpenClaw エージェントがファイル出力後にこのスクリプトを `bash scripts/run-daily.sh` で呼び出す構成
