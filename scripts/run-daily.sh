#!/bin/bash
set -euo pipefail

# ============================================
# run-daily.sh — 毎日の記事収集・公開スクリプト
# cron: 15 9 * * * /path/to/scripts/run-daily.sh
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

log "=== Daily article collection started ==="

# 1. プロジェクトディレクトリに移動
cd "$PROJECT_DIR"

# 2. 最新コード取得
log "Pulling latest changes..."
if ! git pull origin main >> "$LOG_FILE" 2>&1; then
    log "ERROR: git pull failed"
    exit 1
fi

# 3. Claude Code でスキル実行
log "Running research-trend-news skill..."
if claude -p "research-trend-news スキルを実行してください。前日のテックニュースを収集・要約して content/posts/ に出力してください。" \
    --allowedTools 'Bash(curl *),Bash(date *),Read,Write' \
    --max-turns 20 \
    >> "$LOG_FILE" 2>&1; then
    log "Skill execution completed successfully"
else
    log "ERROR: Skill execution failed"
    exit 1
fi

# 4. 変更があるか確認
if git diff --quiet HEAD -- content/posts/ data/processed_urls.json; then
    log "No new articles generated. Skipping commit."
    log "=== Daily run completed (no changes) ==="
    exit 0
fi

# 5. コミット & プッシュ
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
