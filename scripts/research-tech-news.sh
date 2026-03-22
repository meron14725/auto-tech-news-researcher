#!/bin/bash
set -euo pipefail

# ============================================
# research-tech-news.sh — Claude Code に記事収集〜翻訳を委任
# OpenClaw エージェントがスキル実行時にこのスクリプトを呼び出す
# ============================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SKILL_FILE="$PROJECT_DIR/.claude/skills/research-trend-news/SKILL.md"
DATE=$(date +%Y-%m-%d)
YESTERDAY=$(date -d yesterday +%Y-%m-%d 2>/dev/null || date -v-1d +%Y-%m-%d)
LOG_DIR="$PROJECT_DIR/logs"
LOG_FILE="$LOG_DIR/research-$DATE.log"

mkdir -p "$LOG_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "=== Research tech news started ==="
log "Target date: $YESTERDAY"

# 既に記事が存在する場合はスキップ
if [ -f "$PROJECT_DIR/content/posts/$YESTERDAY.md" ]; then
    log "Article for $YESTERDAY already exists. Skipping."
    exit 0
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
fi

log "=== Research tech news completed ==="
