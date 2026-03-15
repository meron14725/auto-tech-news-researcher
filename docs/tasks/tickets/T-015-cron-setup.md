# T-015: cron ジョブ設定

## 概要
VPS 上で `scripts/run-daily.sh` を毎日 JST 9:15 に自動実行する cron ジョブを設定する。

## 前提
- T-013（VPS セットアップ）完了済み
- T-014（Claude Code 認証）完了済み
- タイムゾーンが JST に設定済み

## 手順

### 1. スクリプトの実行権限確認
```bash
cd /home/deploy/auto-tech-news-researcher
chmod +x scripts/run-daily.sh

# 手動で一度実行して動作確認
./scripts/run-daily.sh
```

### 2. cron ジョブ登録
```bash
crontab -e
```

以下を追記:
```cron
# 環境変数（cron はデフォルトで最小限の環境しか持たない）
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
CLAUDE_CODE_OAUTH_TOKEN=<トークン>

# 毎日 JST 9:15 に記事収集
15 9 * * * /home/deploy/auto-tech-news-researcher/scripts/run-daily.sh >> /home/deploy/auto-tech-news-researcher/logs/cron.log 2>&1
```

### 3. 登録確認
```bash
crontab -l
# → 上記のエントリが表示されること
```

### 4. 動作確認
テスト用に直近の時刻に設定して実行を確認:
```bash
# 例: 2分後に設定
crontab -e
# 17 14 * * * /home/deploy/...  ← 現在時刻の2分後に変更

# ログを監視
tail -f /home/deploy/auto-tech-news-researcher/logs/cron.log

# 確認後、本来の時刻 (15 9) に戻す
```

### 5. 将来追加予定の cron（Phase 5）
```cron
# 2日ごと JST 23:00 にスキル改善（T-026 完了後に追加）
# 0 23 */2 * * /home/deploy/auto-tech-news-researcher/scripts/run-improve.sh >> /home/deploy/auto-tech-news-researcher/logs/improve-cron.log 2>&1
```

## 完了条件
- `crontab -l` でジョブが登録されている
- 指定時刻にスクリプトが自動実行される
- ログが `logs/cron.log` に正しく出力される

## トラブルシューティング
- **cron が動かない**: `sudo systemctl status cron` でサービス稼働を確認
- **環境変数が読めない**: crontab 内で `PATH` と `CLAUDE_CODE_OAUTH_TOKEN` を直接定義しているか確認
- **git push 失敗**: SSH 鍵の権限（600）と ssh-agent の設定を確認
- **claude コマンドが見つからない**: crontab の `PATH` に `/usr/local/bin` が含まれているか確認
