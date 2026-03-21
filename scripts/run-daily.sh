#!/bin/bash
set -euo pipefail

# ============================================
# run-daily.sh — 記事公開用 git 操作ラッパー
# OpenClaw エージェントがスキル実行後にこのスクリプトを呼び出す
# ============================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DATE=$(date +%Y-%m-%d)
LOG_DIR="$PROJECT_DIR/logs"
LOG_FILE="$LOG_DIR/daily-$DATE.log"

mkdir -p "$LOG_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "=== Daily git operations started ==="

# 1. プロジェクトディレクトリに移動
cd "$PROJECT_DIR"

# 2. 最新コード取得
log "Pulling latest changes..."
if ! git pull origin main >> "$LOG_FILE" 2>&1; then
    log "ERROR: git pull failed"
    exit 1
fi

# 3. 変更があるか確認
if git diff --quiet HEAD -- content/posts/ data/processed_urls.json 2>/dev/null && \
   [ -z "$(git ls-files --others --exclude-standard content/posts/ data/)" ]; then
    log "No new articles found. Skipping commit."
    log "=== Daily run completed (no changes) ==="
    exit 0
fi

# 4. コミット & プッシュ
YESTERDAY=$(date -d yesterday +%Y-%m-%d 2>/dev/null || date -v-1d +%Y-%m-%d)
log "Committing articles for $YESTERDAY..."

git add content/posts/ data/processed_urls.json
git commit -m "Add articles for $YESTERDAY" >> "$LOG_FILE" 2>&1

log "Pushing to remote..."
if ! git push origin main >> "$LOG_FILE" 2>&1; then
    log "ERROR: git push failed"
    exit 1
fi

log "=== Daily run completed successfully ==="
