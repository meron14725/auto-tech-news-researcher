#!/bin/bash
set -euo pipefail

# ============================================
# research-tech-news.sh — Claude Code に記事収集〜翻訳を委任
# OpenClaw エージェントがスキル実行時にこのスクリプトを呼び出す
# ============================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SKILL_FILE="$PROJECT_DIR/.claude/skills/research-trend-news/SKILL.md"
TOR_DIR="/tmp/tor"
TOR_LOG="/tmp/tor.log"
TOR_DATA="/tmp/tor-data"
DATE=$(date +%Y-%m-%d)
YESTERDAY=$(date -d yesterday +%Y-%m-%d 2>/dev/null || date -v-1d +%Y-%m-%d)
LOG_DIR="$PROJECT_DIR/logs"
LOG_FILE="$LOG_DIR/research-$DATE.log"

mkdir -p "$LOG_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Tor SOCKS5 プロキシの起動（Reddit アクセス用）
start_tor() {
    if [ ! -f "$TOR_DIR/tor" ]; then
        log "Tor binary not found. Skipping Reddit source."
        return 1
    fi
    # 既に起動中なら再利用
    if pgrep -f "$TOR_DIR/tor" > /dev/null 2>&1; then
        log "Tor already running."
        return 0
    fi
    log "Starting Tor SOCKS5 proxy..."
    LD_LIBRARY_PATH="$TOR_DIR" "$TOR_DIR/tor" \
        --SocksPort 9050 \
        --DataDirectory "$TOR_DATA" \
        --Log "notice file $TOR_LOG" &
    # Bootstrap 完了を待つ（最大60秒）
    for i in $(seq 1 60); do
        if grep -q "Bootstrapped 100%" "$TOR_LOG" 2>/dev/null; then
            log "Tor bootstrapped successfully."
            return 0
        fi
        sleep 1
    done
    log "WARNING: Tor bootstrap timed out."
    return 1
}

stop_tor() {
    pkill -f "$TOR_DIR/tor" 2>/dev/null || true
}

# クリーンアップ
cleanup() {
    stop_tor
}
trap cleanup EXIT

log "=== Research tech news started ==="
log "Target date: $YESTERDAY"

# 既に記事が存在する場合はスキップ
if [ -f "$PROJECT_DIR/content/posts/$YESTERDAY.md" ]; then
    log "Article for $YESTERDAY already exists. Skipping."
    exit 0
fi

# Tor 起動（Reddit 用）
TOR_AVAILABLE="no"
if start_tor; then
    TOR_AVAILABLE="yes"
fi

# Claude Code headless で記事収集〜翻訳を実行
log "Invoking Claude Code headless mode..."

PROMPT="$(cat <<EOF
あなたは技術ニュース収集エージェントです。以下のスキル定義に従って、記事の収集・フィルタリング・日本語要約を実行してください。

## スキル定義
まず $SKILL_FILE を読んで、処理フローの詳細を確認してください。

## 実行指示
- 対象日付: $YESTERDAY
- プロジェクトディレクトリ: $PROJECT_DIR
- 処理済みURL: $PROJECT_DIR/data/processed_urls.json
- 出力先: $PROJECT_DIR/content/posts/$YESTERDAY.md

スキル定義の処理フロー（準備 → 記事取得 → 2段階フィルタリング → 日本語要約生成 → ファイル出力）を忠実に実行してください。

重要な注意事項:
- 日本語のみで出力すること（中国語・韓国語・ロシア語の混入は厳禁）
- 技術用語は原語のままカタカナ化しないこと（例: LLM, API, Kubernetes はそのまま）
- 要約は記事の技術的内容を具体的に説明すること（空虚な一般論は避ける）
- curl コマンドでデータを取得すること
- 記事が0件の場合はファイルを生成しないこと

Reddit アクセス方法:
- Tor SOCKS5 プロキシ状態: $TOR_AVAILABLE
- Reddit へのアクセスは Hetzner IP がブロックされているため、Tor プロキシ経由で行うこと
- コマンド: curl -s --socks5-hostname 127.0.0.1:9050 -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64)" "URL"
- 429 エラーが返る場合は数秒待ってリトライすること（最大3回）
- Tor が利用不可（$TOR_AVAILABLE=no）の場合は Reddit をスキップし、他ソースで補完すること
EOF
)"

if claude -p "$PROMPT" \
    --allowedTools "Read,Write,Edit,Bash,Grep,Glob" \
    --output-format text \
    --max-turns 50 \
    >> "$LOG_FILE" 2>&1; then
    log "Claude Code execution completed successfully."
else
    EXIT_CODE=$?
    log "ERROR: Claude Code execution failed (exit code: $EXIT_CODE)"
    exit 1
fi

# 出力ファイルの存在確認
if [ -f "$PROJECT_DIR/content/posts/$YESTERDAY.md" ]; then
    log "Article file generated: content/posts/$YESTERDAY.md"
else
    log "WARNING: No article file generated (possibly 0 articles matched criteria)"
    log "=== Research tech news completed (no articles) ==="
    exit 0
fi

# Git commit & push（run-daily.sh を呼び出し）
log "Running git operations..."
if bash "$PROJECT_DIR/scripts/run-daily.sh" >> "$LOG_FILE" 2>&1; then
    log "Git push completed successfully."
else
    log "ERROR: Git push failed."
    exit 1
fi

log "=== Research tech news completed ==="
