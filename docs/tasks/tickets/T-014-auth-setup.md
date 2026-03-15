# T-014: Claude Code CLI 認証設定

## 概要
VPS 上で Claude Code CLI を非対話モードで実行するための認証（`CLAUDE_CODE_OAUTH_TOKEN`）を設定する。

## 手順

### 1. トークン発行（ローカル PC で実行）
```bash
claude setup-token
```
- 表示される URL をブラウザで開く
- Anthropic アカウントで認証
- トークン文字列が表示されるのでコピー
- 有効期限: 1年間

### 2. VPS にトークンを設定
```bash
# VPS にログイン
ssh deploy@<VPS_IP>

# 環境変数ファイルに設定（cron からも参照可能にする）
echo 'CLAUDE_CODE_OAUTH_TOKEN=<コピーしたトークン>' | sudo tee -a /etc/environment

# 現在のセッションにも反映
export CLAUDE_CODE_OAUTH_TOKEN=<コピーしたトークン>
```

### 3. 動作確認
```bash
# 対話モードなしで Claude が応答するか確認
claude -p "Hello, respond with 'OK' only."
# → "OK" と返れば成功
```

### 4. cron からの参照確認
```bash
# cron 環境で環境変数が読めるか確認
env -i /bin/bash -c 'source /etc/environment && echo $CLAUDE_CODE_OAUTH_TOKEN'
# → トークンが表示されれば OK
```

### 5. トークン期限リマインダー
```bash
# 1年後のリマインダーを cron で設定
EXPIRY=$(date -d "+1 year" +%Y-%m-%d)
echo "Claude Code token expires on $EXPIRY — run 'claude setup-token' to renew"

# カレンダーアプリや Issue に期限を記録しておく
```

## 完了条件
- VPS 上で `claude -p` が正常に動作する
- cron 経由でも認証が通る
- トークン期限のリマインダーが設定されている

## 注意事項
- トークンは機密情報。`/etc/environment` に書く場合は他のユーザーから読めないよう権限に注意
- `.bashrc` ではなく `/etc/environment` を使う理由: cron は `.bashrc` を読み込まないため
- 代替: crontab 内で直接 `CLAUDE_CODE_OAUTH_TOKEN=xxx` を指定する方法もある
