# T-014: MiniMax API 認証設定

## 概要
OpenClaw で MiniMax M2.5 を使うための API キーと、Cloudflare API 認証情報を設定する。

## 依存
- T-013.5（OpenClaw Gateway 設定）

## 手順

### 1. MiniMax API キー取得
1. [MiniMax Platform](https://platform.minimax.io/) にサインアップ
2. API Keys ページでキーを発行
3. 無料クレジットの有無を確認

### 2. OpenClaw に API キーを設定
```bash
# 環境変数として設定
echo 'export MINIMAX_API_KEY=<your-key>' >> ~/.bashrc
source ~/.bashrc

# openclaw.json の apiKey フィールドで参照される
```

### 3. 動作確認
```bash
# OpenClaw 経由で MiniMax が応答するか確認
# Gateway にテストメッセージを送信
```

### 4. Cloudflare API 認証情報（フィードバック用）
```bash
echo 'export CF_ACCOUNT_ID=<account-id>' >> ~/.bashrc
echo 'export CF_KV_NAMESPACE_ID=<namespace-id>' >> ~/.bashrc
echo 'export CF_API_TOKEN=<api-token>' >> ~/.bashrc
source ~/.bashrc
```

## 完了条件
- OpenClaw エージェントが MiniMax M2.5 で応答する
- Cloudflare 認証情報が設定済み（Phase 5 で使用）

**ステータス**: ✅ 完了（2026-03-22）※ Cloudflare 認証は Phase 5 で設定予定

## 完了メモ
- MiniMax Coding Plan Starter ($10/月) を契約、APIキー (`sk-cp-*`) を取得
- APIキーは `~/.openclaw/.env` および `openclaw.json` に設定済み
- systemd サービスに EnvironmentFile オーバーライドで `.env` を読み込み設定
- OpenAI互換エンドポイント (`https://api.minimax.io/v1`) で接続確認済み
- Cloudflare 認証情報は Phase 5 (T-022〜) で設定する
