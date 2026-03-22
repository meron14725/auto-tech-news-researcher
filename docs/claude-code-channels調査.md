# Claude Code Channels & 外部連携機能 調査レポート

> 調査日: 2026-03-22
> Claude Code バージョン: 2.1.81
> 目的: OpenClaw オーケストレーターから Claude Code にタスクを委任する最適な方法を調査

---

## 1. Claude Code Channels

### 概要

Channels は MCP (Model Context Protocol) サーバーが**実行中の Claude Code セッションにイベントをプッシュ**する仕組み。従来のポーリングやセッション生成ではなく、既に開いているターミナルセッションに直接メッセージを配信する。

### 主な特徴

- **リサーチプレビュー段階**（v2.1.80+ 必要）
- セッションが開いている間のみイベントを受信
- claude.ai ログインが必要（Console API キーや Enterprise キーは非対応）
- Bun ランタイムが推奨（Node.js/Deno も可）

### 利用可能なチャンネル

| チャンネル | 説明 | ユースケース |
|-----------|------|-------------|
| Telegram | Bot 経由で DM を受信 | モバイルからの指示送信 |
| Discord | サーバーメッセージを受信 | チーム連携 |
| Fakechat | localhost:8787 のデモ | テスト・開発用 |
| Webhook（カスタム） | HTTP POST を受信 | CI/CD、監視、外部システム連携 |

### アーキテクチャ

```
外部システム → ローカル Channel サーバー → Claude Code (stdio transport)
```

### 通知プロトコル

Channels は `notifications/claude/channel` イベントを発行:

```json
{
  "content": "イベント本文",
  "meta": {
    "path": "/webhook/path",
    "severity": "high"
  }
}
```

Claude Code セッション内では以下のように表示:

```xml
<channel source="webhook" path="/webhook/path" severity="high">
イベント本文
</channel>
```

### カスタム Webhook チャンネルの実装例

```typescript
#!/usr/bin/env bun
import { Server } from '@modelcontextprotocol/sdk/server/index.js'
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js'

const mcp = new Server(
  { name: 'webhook', version: '0.0.1' },
  {
    capabilities: { experimental: { 'claude/channel': {} } },
    instructions: 'Events from webhook channel. One-way, read and act.',
  },
)

await mcp.connect(new StdioServerTransport())

Bun.serve({
  port: 8788,
  hostname: '127.0.0.1',
  async fetch(req) {
    const body = await req.text()
    await mcp.notification({
      method: 'notifications/claude/channel',
      params: {
        content: body,
        meta: { path: new URL(req.url).pathname, method: req.method },
      },
    })
    return new Response('ok')
  },
})
```

設定（`.mcp.json`）:

```json
{
  "mcpServers": {
    "webhook": { "command": "bun", "args": ["./webhook.ts"] }
  }
}
```

実行:

```bash
claude --dangerously-load-development-channels server:webhook
curl -X POST localhost:8788 -d "build failed: https://ci.example.com/1234"
```

### 双方向通信

Channels は `reply` ツールを公開でき、Claude Code がチャンネル経由で返信可能:

- Telegram: ユーザーが DM → Claude が同じチャットに返信
- Webhook: レスポンスをコールバック URL に POST

### Enterprise 対応

- `channelsEnabled` 設定で管理者が有効/無効を制御
- ペアリングフロー（送信者許可リスト）でセキュリティ確保

---

## 2. Headless CLI (`claude -p`)

### 概要

非対話モードで Claude Code を実行。外部スクリプトやオーケストレーターからの呼び出しに最適。

### 基本的な使い方

```bash
# 基本
claude -p "プロンプト"

# ツール制限付き
claude -p "タスク内容" \
  --allowedTools "Read,Write,Bash,Grep,Glob" \
  --output-format text \
  --max-turns 30

# JSON 出力
claude -p "分析して" --output-format json | jq '.result'

# ストリーミング
claude -p "ドキュメント書いて" --output-format stream-json

# セッション継続
SESSION=$(claude -p "分析開始" --output-format json | jq -r '.session_id')
claude -p "続きを実行" --resume "$SESSION"
```

### 主要オプション

| オプション | 説明 |
|-----------|------|
| `-p, --print` | 非対話モード |
| `--continue` | 前回セッション継続 |
| `--resume SESSION_ID` | 特定セッション再開 |
| `--allowedTools "Tool1,Tool2"` | ツール事前承認 |
| `--output-format text\|json\|stream-json` | 出力形式 |
| `--json-schema SCHEMA` | 構造化出力スキーマ |
| `--append-system-prompt TEXT` | システムプロンプト追加 |
| `--system-prompt TEXT` | システムプロンプト完全置換 |
| `--max-turns N` | 最大ターン数 |

### 利用可能なツール

| ツール | 用途 |
|--------|------|
| Read | ファイル読み込み |
| Write | 新規ファイル作成 |
| Edit | 既存ファイル編集 |
| Bash | シェルコマンド実行 |
| Glob | パターンでファイル検索 |
| Grep | 正規表現でコンテンツ検索 |
| WebSearch | Web 検索 |
| WebFetch | Web ページ取得 |

### エラーハンドリング

API エラー時は `system/api_retry` イベントを発行:

```json
{
  "type": "system",
  "subtype": "api_retry",
  "attempt": 1,
  "max_retries": 3,
  "error_status": 429
}
```

---

## 3. Agent SDK (Python / TypeScript)

### 概要

Claude Code をプログラマティックに制御する SDK。プロダクション環境、CI/CD、カスタムアプリケーション向け。

### Python 例

```python
import asyncio
from claude_agent_sdk import query, ClaudeAgentOptions

async def main():
    async for message in query(
        prompt="auth.py のバグを修正して",
        options=ClaudeAgentOptions(
            allowed_tools=["Read", "Edit", "Bash"],
            permission_mode="acceptEdits",
            cwd="/path/to/project"
        ),
    ):
        if hasattr(message, "result"):
            print(message.result)

asyncio.run(main())
```

### TypeScript 例

```typescript
import { query } from "@anthropic-ai/claude-agent-sdk";

async function main() {
  for await (const message of query({
    prompt: "auth.ts のバグを修正して",
    options: {
      allowedTools: ["Read", "Edit", "Bash"],
      permissionMode: "acceptEdits",
      cwd: "/path/to/project"
    }
  })) {
    if ("result" in message) console.log(message.result);
  }
}
```

### ClaudeAgentOptions の主要プロパティ

| プロパティ | 説明 |
|-----------|------|
| `allowed_tools` | 許可するツールのリスト |
| `permission_mode` | `default`, `acceptEdits`, `bypassPermissions`, `dontAsk` |
| `system_prompt` | カスタムシステムプロンプト |
| `cwd` | 作業ディレクトリ |
| `model` | モデル選択 |
| `mcp_servers` | MCP サーバー設定 |
| `agents` | サブエージェント定義 |
| `hooks` | フック定義 |
| `resume` | セッション ID で再開 |

### SDK vs CLI 比較

| 観点 | Headless CLI | Agent SDK |
|------|-------------|-----------|
| インターフェース | bash コマンド | Python/TypeScript API |
| セットアップ | ゼロ（CLI のみ） | SDK インストール必要 |
| ユースケース | スクリプト、cron | プロダクション、複雑なワークフロー |
| ツールループ | 自動 | 自動（より細かい制御可能） |
| 最適な場面 | 1 回限りのタスク | 繰り返し・スケール化ワークフロー |

---

## 4. Hooks

### 概要

Claude Code セッション内のライフサイクルイベントに応じてシェルコマンドを実行する仕組み。

### 利用可能なイベント

| イベント | 発火タイミング | 例 |
|---------|--------------|-----|
| `SessionStart` | セッション開始/再開時 | 環境変数の注入 |
| `PreToolUse` | ツール実行前 | 保護ファイルへのアクセスブロック |
| `PostToolUse` | ツール実行成功後 | Prettier で自動フォーマット |
| `PermissionRequest` | 権限ダイアログ表示時 | 信頼ツールの自動承認 |
| `Stop` | Claude の応答完了時 | タスク完了の検証 |
| `UserPromptSubmit` | プロンプト送信時 | 入力のログ記録 |

### 設定例

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "jq -r '.tool_input.file_path' | xargs npx prettier --write"
          }
        ]
      }
    ]
  }
}
```

### 重要な制限事項

- **外部システムからのトリガー不可**: Hooks は Claude Code セッション内部でのみ動作
- スリープ中のセッションを起動することはできない
- Webhook を直接受信することはできない（→ Channels を使用）

---

## 5. MCP 統合

### Claude Code が MCP サーバーを消費

```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["@github-tools/server@latest"]
    },
    "postgres": {
      "command": "node",
      "args": ["/usr/local/bin/postgres-mcp.js"],
      "env": { "DATABASE_URL": "postgresql://..." }
    }
  }
}
```

設定の優先順位:
1. **プロジェクトスコープ**: `.mcp.json`（最優先）
2. **ユーザースコープ**: `~/.claude.json`
3. **プラグイン**: 付属の MCP サーバー
4. **管理設定**: Enterprise のみ

### Claude Code を MCP サーバーとして公開

Claude Code は MCP サーバーとしてリモートシステムに機能を公開可能。外部オーケストレーターが Claude Code のツール（Read, Edit, Bash 等）を MCP 経由で呼び出せる。

ただし **Agent SDK や Headless CLI の方が安定的で推奨**。

---

## 6. OpenClaw 連携パターン比較

### パターン一覧

| パターン | 方向 | 常駐必要 | 実装コスト | 安定性 | 推奨度 |
|---------|------|---------|-----------|--------|--------|
| **Headless CLI** (`claude -p` via bash) | OpenClaw → Claude Code | 不要 | 低 | 高 | **◎** |
| Agent SDK (Python) | OpenClaw → Claude Code | 不要 | 中 | 高 | △ |
| Channels (Webhook) | 外部 → Claude Code | 要 | 中 | 中 | × |
| MCP サーバー公開 | OpenClaw → Claude Code | 不要 | 高 | 低 | × |

### 推奨: Headless CLI (`claude -p`) via bash

**理由:**

1. **インフラ追加ゼロ**: Claude Code CLI は既にサーバーにインストール・認証済み
2. **OpenClaw の bash ツールから直接呼べる**: 追加の SDK やラッパー不要
3. **コスト追加ゼロ**: Max 5x サブスクリプションに含まれる
4. **シンプル**: シェルスクリプト 1 つで統合完了
5. **デバッグ容易**: スクリプトを手動実行してテスト可能

**不採用理由:**

- **Agent SDK**: Python SDK のインストールが必要。この規模では過剰
- **Channels**: 方向が逆（Claude Code にイベントを push する仕組み）。OpenClaw → Claude Code の委任には不向き
- **MCP 公開**: 実験的機能で安定性に懸念

---

## 7. 採用アーキテクチャ: OpenClaw → Claude Code 全委任

### パイプライン

```
[JST 9:15] OpenClaw cron
    │
    ▼
[OpenClaw] スキル実行（オーケストレーション）
    │
    ▼
[bash] scripts/research-tech-news.sh
    │
    ▼
[Claude Code headless] claude -p
    ├─ curl: HN/Zenn/dev.to から記事取得
    ├─ processed_urls.json で重複排除
    ├─ 2段階フィルタリング + スコアリング
    ├─ 日本語タイトル + 要約生成
    ├─ content/posts/YYYY-MM-DD.md 出力
    └─ data/processed_urls.json 更新
    │
    ▼
[bash] scripts/run-daily.sh
    └─ git add → commit → push → Cloudflare Pages
```

### メリット

- **翻訳品質の根本解決**: MiniMax の多言語混入問題を完全に回避
- **アーキテクチャ簡素化**: Gemini API（T-029）が不要、LLM プロバイダーの追加なし
- **コスト**: 追加 $0（Max 5x に含まれる）
- **記事品質向上**: Claude の深い読解力と自然な日本語生成

### コスト影響

| 項目 | 変更前 | 変更後 |
|------|--------|--------|
| Hetzner CX33 | $6.43/月 | $6.43/月（変更なし） |
| MiniMax | $10/月 | $10/月（他タスクで継続利用） |
| Claude Code | $0（Max 5x に含む） | $0（1日1プロンプト、枠内で十分） |
| Gemini API | 導入予定だった | **不要に** |

---

## 参考リンク

- Channels ドキュメント: https://docs.anthropic.com/en/docs/claude-code/channels
- Channels リファレンス（カスタム構築）: https://docs.anthropic.com/en/docs/claude-code/channels-reference
- Headless モード: https://docs.anthropic.com/en/docs/claude-code/headless
- Agent SDK: https://docs.anthropic.com/en/docs/agent-sdk
- Hooks ガイド: https://docs.anthropic.com/en/docs/claude-code/hooks
- MCP: https://docs.anthropic.com/en/docs/claude-code/mcp
