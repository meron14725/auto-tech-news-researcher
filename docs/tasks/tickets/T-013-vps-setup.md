# T-013: ConoHa VPS セットアップ

## 概要
ConoHa VPS（Ubuntu 24.04, 1GB）を契約・初期設定し、パイプラインが動作する環境を構築する。

## やること
- ConoHa VPS 1GB プランの契約（まとめトク1ヶ月 763円）
- Ubuntu 24.04 の初期設定
  - SSH 鍵認証のみ許可（パスワード認証無効化）
  - UFW（ファイアウォール）有効化
  - `apt update && apt upgrade`
- 必要パッケージのインストール
  - Git
  - Node.js（Claude Code CLI の動作要件）
  - Claude Code CLI（`npm install -g @anthropic-ai/claude-code`）
  - Hugo（snap or バイナリ直接配置）
- GitHub への SSH 鍵設定（git push 用）

## 完了条件
- SSH で VPS にログインできる
- `claude --version` が動作する
- `git clone` でリポジトリをクローンできる
