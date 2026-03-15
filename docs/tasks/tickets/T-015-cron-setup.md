# T-015: cron ジョブ設定

## 概要
VPS 上で `scripts/run-daily.sh` を毎日 JST 9:15 に自動実行する cron ジョブを設定する。

## やること
- VPS のタイムゾーンを JST（Asia/Tokyo）に設定
- `crontab -e` で cron ジョブを登録
  - `15 9 * * * /path/to/scripts/run-daily.sh >> /path/to/logs/cron.log 2>&1`
- 環境変数が cron から参照できることを確認
- 実行権限の付与: `chmod +x scripts/run-daily.sh`

## 完了条件
- `crontab -l` でジョブが登録されている
- 指定時刻にスクリプトが自動実行される
- ログが正しく出力される
