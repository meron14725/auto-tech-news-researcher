# T-015: OpenClaw cron ジョブ設定

## 概要
OpenClaw の内蔵 cron 機能を使い、毎日 JST 9:15 にニュース収集を自動実行する。

## 依存
- T-012（run-daily.sh 修正）
- T-014（認証設定）
- T-014.5（スキル変換）

## 手順

### 1. 日次ニュース収集 cron 登録
```bash
openclaw cron add \
  --name "daily-news-collection" \
  --cron "15 9 * * *" \
  --tz "Asia/Tokyo" \
  --session isolated \
  --message "research-trend-news スキルを実行してください。前日のテックニュースを収集・要約して content/posts/ に出力してください。完了後、scripts/run-daily.sh を実行して git commit & push してください。"
```

### 2. 登録確認
```bash
openclaw cron list
```

### 3. テスト実行
直近の時刻に一時的に変更して動作確認:
```bash
# ログを監視しながらテスト
```

### 4. Gateway 自動起動確認
```bash
# VPS 再起動後も Gateway が起動することを確認
sudo reboot
# 再接続後
systemctl --user status openclaw-gateway
openclaw cron list
```

### 5. 将来追加予定（Phase 5 完了後）
```bash
# 2日ごとのスキル改善 cron（T-026 で追加）
openclaw cron add \
  --name "skill-improvement" \
  --cron "0 23 */2 * *" \
  --tz "Asia/Tokyo" \
  --session isolated \
  --message "..."
```

## 完了条件
- `openclaw cron list` でジョブが登録されている
- 指定時刻にスキルが自動実行される
- 記事が生成され git push される
- VPS 再起動後もジョブが維持される
