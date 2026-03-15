# T-013: ConoHa VPS セットアップ

## 概要
ConoHa VPS（Ubuntu 24.04, 1GB）を契約・初期設定し、パイプラインが動作する環境を構築する。

## 手順

### 1. VPS 契約
1. [ConoHa](https://www.conoha.jp/) にログイン
2. VPS → サーバー追加 → 1GB プラン（まとめトク1ヶ月 763円）
3. OS: Ubuntu 24.04
4. root パスワードを設定（後で SSH 鍵に切り替える）
5. IPアドレスをメモ

### 2. SSH 初期設定
```bash
# ローカル PC から接続
ssh root@<VPS_IP>

# 作業用ユーザー作成
adduser deploy
usermod -aG sudo deploy

# SSH 鍵設定（ローカル PC で実行）
ssh-copy-id deploy@<VPS_IP>

# VPS 側: パスワード認証を無効化
sudo vim /etc/ssh/sshd_config
# PasswordAuthentication no
# PermitRootLogin no
sudo systemctl restart sshd
```

### 3. ファイアウォール設定
```bash
sudo ufw allow OpenSSH
sudo ufw enable
sudo ufw status
```

### 4. パッケージ更新 & 必要ツールのインストール
```bash
sudo apt update && sudo apt upgrade -y

# Git
sudo apt install -y git

# Node.js (Claude Code CLI の動作要件)
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt install -y nodejs
node -v  # v22.x を確認

# Claude Code CLI
sudo npm install -g @anthropic-ai/claude-code
claude --version

# Hugo
# Cloudflare Pages と同じバージョンを使う（hugo.toml 参照）
wget https://github.com/gohugoio/hugo/releases/download/v0.157.0/hugo_extended_0.157.0_linux-arm64.deb
sudo dpkg -i hugo_extended_0.157.0_linux-arm64.deb
hugo version

# jq（フィードバックスクリプトで使用）
sudo apt install -y jq
```

### 5. GitHub SSH 鍵設定
```bash
# VPS 上で SSH 鍵を生成
ssh-keygen -t ed25519 -C "deploy@conoha-vps"

# 公開鍵を表示 → GitHub の Settings > SSH keys に登録
cat ~/.ssh/id_ed25519.pub

# 接続テスト
ssh -T git@github.com
```

### 6. リポジトリクローン
```bash
cd /home/deploy
git clone git@github.com:<ユーザー名>/auto-tech-news-researcher.git
cd auto-tech-news-researcher
git submodule update --init --recursive  # PaperMod テーマ取得
```

### 7. タイムゾーン設定
```bash
sudo timedatectl set-timezone Asia/Tokyo
date  # JST であることを確認
```

## 完了条件
- SSH で VPS にログインできる
- `claude --version` が動作する
- `hugo version` が動作する
- `git clone` でリポジトリをクローンできる
- タイムゾーンが JST になっている

## 注意事項
- VPS が ARM64 か AMD64 かで Hugo のダウンロード URL が変わる。ConoHa は AMD64 なので `linux-amd64.deb` を使用
- Node.js は LTS バージョン（22.x）を推奨
