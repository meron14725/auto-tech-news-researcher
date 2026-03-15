# T-014: Claude Code CLI 認証設定

## 概要
VPS 上で Claude Code CLI を非対話モードで実行するための認証（`CLAUDE_CODE_OAUTH_TOKEN`）を設定する。

## やること
- ローカル PC で `claude setup-token` を実行してトークン発行
- VPS の環境変数に `CLAUDE_CODE_OAUTH_TOKEN` を設定
  - `/etc/environment` または `~/.bashrc` に記載
  - cron からも参照できるように設定
- トークンの有効期限管理（1年後にリマインダー設定）
- 動作確認: `claude -p "hello"` が応答を返すこと

## 完了条件
- VPS 上で `claude -p` が正常に動作する
- cron 経由でも認証が通る
- トークン期限のリマインダーが設定されている
