# T-013: Hetzner CX33 セットアップ

## 概要
Hetzner Cloud CX33（4 vCPU / 8 GB RAM / 80 GB NVMe）をプロビジョニングし、OpenClaw が動作する環境を構築する。

## 手順

### 1. VPS プロビジョニング
1. [Hetzner Cloud Console](https://console.hetzner.cloud/) にログイン
2. 新規プロジェクト作成 → サーバー追加
3. プラン: **CX33**（4 vCPU / 8 GB RAM / 80 GB NVMe）
4. ロケーション: EU（Falkenstein or Nuremberg）
5. OS: Ubuntu 24.04
6. SSH 公開鍵を登録
7. サーバー作成 → IP アドレスをメモ

### 2. SSH 初期設定
```bash
ssh root@<VPS_IP>

# 作業用ユーザー作成
adduser deploy
usermod -aG sudo deploy

# ローカル PC で SSH 鍵コピー
ssh-copy-id deploy@<VPS_IP>

# パスワード認証無効化
sudo vim /etc/ssh/sshd_config
# PasswordAuthentication no
# PermitRootLogin no
sudo systemctl restart sshd
```

### 3. ファイアウォール
```bash
sudo ufw allow OpenSSH
sudo ufw enable
```

### 4. パッケージインストール
```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y git jq

# Node.js 22.x
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt install -y nodejs

# Hugo（Cloudflare Pages と同じバージョン）
wget https://github.com/gohugoio/hugo/releases/download/v0.157.0/hugo_extended_0.157.0_linux-amd64.deb
sudo dpkg -i hugo_extended_0.157.0_linux-amd64.deb
```

### 5. GitHub SSH 鍵
```bash
ssh-keygen -t ed25519 -C "deploy@hetzner"
cat ~/.ssh/id_ed25519.pub  # → GitHub Settings > SSH keys に登録
ssh -T git@github.com
```

### 6. リポジトリクローン
```bash
cd /home/deploy
git clone git@github.com:<ユーザー名>/auto-tech-news-researcher.git
cd auto-tech-news-researcher
git submodule update --init --recursive
```

### 7. タイムゾーン・systemd 設定
```bash
sudo timedatectl set-timezone Asia/Tokyo
sudo loginctl enable-linger deploy  # OpenClaw の systemd ユーザーサービス用
```

## 完了条件
- SSH でログインできる
- `node --version` が v22.x
- `hugo version` が動作する
- リポジトリがクローンされている
- タイムゾーンが JST

**ステータス**: ✅ 完了（2026-03-22）

## 完了メモ
- VPS: Hetzner CX33 (4 vCPU / 8 GB RAM), Ubuntu 24.04, Nuremberg
- Node.js v22.22.1, Hugo v0.157.0 extended, git 2.43.0, jq 1.7
- GitHub SSH: Deploy Key（write access）で接続確認済み
- UFW: OpenSSH のみ許可で有効化
- loginctl enable-linger deploy 設定済み
- タイムゾーン: Asia/Tokyo (JST)
