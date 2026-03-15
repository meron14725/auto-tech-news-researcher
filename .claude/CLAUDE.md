# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Automated tech news aggregation site. Collects trending articles from multiple sources daily, summarizes them in Japanese using Claude Code CLI skills, and publishes to a Hugo static site on Cloudflare Pages.

## Architecture

- **Execution**: ConoHa VPS (Ubuntu 24.04) runs `scripts/run-daily.sh` via cron at JST 9:15 daily
- **AI Processing**: `claude -p` with skills (`.claude/skills/research-trend-news/SKILL.md`) — runs within Claude Max 5x subscription, no API costs
- **Data**: Articles stored as `content/posts/YYYY-MM-DD.md` (YAML front matter), deduplication via `data/processed_urls.json`
- **Site**: Hugo SSG, deployed on Cloudflare Pages (auto-builds on push to main)
- **Auth**: `CLAUDE_CODE_OAUTH_TOKEN` environment variable (setup-token, 1-year validity)

## Pipeline Flow

1. cron triggers `run-daily.sh`
2. `git pull origin main`
3. `claude -p` executes the research-trend-news skill with `--allowedTools` and `--max-turns 20`
4. Skill fetches from news sources (RSS/API via curl), filters by interest_score >= 7, generates Japanese summaries
5. Outputs `YYYY-MM-DD.md` (前日の日付、YAML front matter with articles array) and updates `processed_urls.json`
6. `git add && commit && push` to main
7. Cloudflare Pages detects push, runs Hugo build, deploys

## News Sources

| Source | Method | Auth | Priority |
|--------|--------|------|----------|
| Hacker News | Firebase API | None | Phase 1 |
| Zenn | RSS `/feed` | None | Phase 1 |
| dev.to | REST API | None | Phase 1 |
| Qiita | RSS `/popular-items/feed.atom` | None | Phase 2 |
| Reddit | REST API | OAuth2 | Phase 2 |

## Article Data Format

Content files use Markdown with YAML front matter (`content/posts/YYYY-MM-DD.md`):

```yaml
---
title: "YYYY-MM-DD のテックニュース"
date: YYYY-MM-DD
articles:
  - title: "Japanese title"
    original_title: "Original Title"
    source: "hn|zenn|devto|qiita|reddit"
    url: "https://..."
    summary: "3-5 sentence Japanese summary"
    tags: ["AI", "LLM"]
    interest_score: 8
---
```

## Branch Strategy

- All development changes go through feature branches and PRs
- Only daily auto-generated article commits push directly to main
- Branch naming: `feature/*`, `fix/*`

## Key Constraints

- No Anthropic API direct calls — use Claude Code CLI skills only (subscription-based)
- All news sources use official APIs/RSS only — no scraping
- Hugo chosen for minimal dependencies (Go single binary) and fast builds
- Site must work within Cloudflare Pages free tier (20,000 files, 500 builds/month)

## Task Management

- タスク一覧: `docs/tasks/開発タスク.md`、個別チケット: `docs/tasks/tickets/T-XXX-*.md`
- タスク完了時は以下を更新すること:
  1. `開発タスク.md` のチェックボックスを `[x]` にし「✅ 完了」と記載
  2. 該当チケットに「**ステータス**: ✅ 完了（日付）」と「## 完了メモ」セクションを追加
  3. 設計変更があった場合は CLAUDE.md の該当箇所も更新
