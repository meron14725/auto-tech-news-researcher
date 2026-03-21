# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Automated tech news aggregation site. Collects trending articles from multiple sources daily, summarizes them in Japanese using OpenClaw (self-hosted AI agent) + MiniMax M2.5 LLM, and publishes to a Hugo static site on Cloudflare Pages.

## Architecture

> アーキテクチャ図: [docs/architecture.svg](../docs/architecture.svg)

- **Execution**: Hetzner Cloud CX33 (4 vCPU / 8 GB RAM, Ubuntu 24.04) runs OpenClaw Gateway as a systemd service
- **AI Processing**: OpenClaw agent with research-trend-news skill, powered by MiniMax M2.5 API ($0.20/$0.95 per 1M tokens)
- **Scheduling**: OpenClaw built-in cron (daily JST 9:15 for articles, every 2 days JST 23:00 for skill improvement)
- **Data**: Articles stored as `content/posts/YYYY-MM-DD.md` (YAML front matter), deduplication via `data/processed_urls.json`
- **Site**: Hugo SSG + PaperMod theme, deployed on Cloudflare Pages (auto-builds on push to main)
- **Feedback**: 👍👎 UI → Cloudflare Pages Function → Cloudflare KV → skill improvement loop

## Pipeline Flow

1. OpenClaw cron triggers at JST 9:15
2. Agent executes research-trend-news skill
3. Skill fetches from news sources (RSS/API via curl), filters by interest_score >= 7, generates Japanese summaries
4. Outputs `YYYY-MM-DD.md` (前日の日付、YAML front matter with articles array) and updates `processed_urls.json`
5. Agent calls `scripts/run-daily.sh` for git pull → add → commit → push
6. Cloudflare Pages detects push, runs Hugo build, deploys

## Feedback Improvement Loop

1. User rates articles with 👍👎 buttons on the site
2. Ratings stored in Cloudflare KV via Pages Function (`/api/feedback`)
3. Every 2 days at JST 23:00, OpenClaw cron triggers improvement
4. `scripts/fetch-feedback.sh` pulls ratings from KV → `data/feedback.json`
5. Agent analyzes feedback and improves SKILL.md
6. `scripts/run-improve.sh` commits and pushes changes

## News Sources

| Source | Method | Auth | Priority |
|--------|--------|------|----------|
| Hacker News | Firebase API | None | Phase 1 |
| Zenn | RSS `/feed` | None | Phase 1 |
| dev.to | REST API | None | Phase 1 |
| Qiita | RSS `/popular-items/feed.atom` | None | Phase 3 |
| Reddit | REST API | OAuth2 | Phase 3 |

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

- All news sources use official APIs/RSS only — no scraping
- Hugo chosen for minimal dependencies (Go single binary) and fast builds
- Site must work within Cloudflare Pages free tier (20,000 files, 500 builds/month)
- LLM API costs should stay under $5/month for daily article collection

## Task Management

- タスク一覧: `docs/tasks/開発タスク.md`、個別チケット: `docs/tasks/tickets/T-XXX-*.md`
- タスク完了時は以下を更新すること:
  1. `開発タスク.md` のチェックボックスを `[x]` にし「✅ 完了」と記載
  2. 該当チケットに「**ステータス**: ✅ 完了（日付）」と「## 完了メモ」セクションを追加
  3. 設計変更があった場合は CLAUDE.md の該当箇所も更新
