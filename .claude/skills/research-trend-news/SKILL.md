# research-trend-news

技術トレンドニュースを複数ソースから収集し、日本語で要約して記事ファイルを生成するスキル。

## 処理フロー

### 1. 準備
- 前日の日付を取得（`date -d yesterday +%Y-%m-%d`、macOS では `date -v-1d +%Y-%m-%d`）
- `data/processed_urls.json` を読み込み、処理済み URL リストを取得
- 既に `content/posts/{前日の日付}.md` が存在する場合は処理をスキップ

### 2. 記事取得

以下のソースから記事を取得する。各ソースで取得に失敗しても他のソースの処理は続行する。
**各ソースから最低30件は取得**し、十分な候補を確保すること。

#### Hacker News（Firebase API）
```bash
# トップ50記事のIDを取得
curl -s "https://hacker-news.firebaseio.com/v0/topstories.json" | head -c 800

# 各記事の詳細を取得（上位50件）
curl -s "https://hacker-news.firebaseio.com/v0/item/{id}.json"
```

#### Zenn（RSS）
```bash
curl -s "https://zenn.dev/feed"
```

#### dev.to（REST API）
```bash
curl -s "https://dev.to/api/articles?per_page=30&top=1"
```

#### Reddit（JSON API — Tor SOCKS5 プロキシ経由）

Hetzner IP は Reddit にブロックされているため、Tor プロキシ（127.0.0.1:9050）経由でアクセスする。
プロンプト内で Tor の利用可否が通知される。`$TOR_AVAILABLE=no` の場合は Reddit をスキップすること。

```bash
# Tor 経由の curl コマンドテンプレート
REDDIT_CURL="curl -s --socks5-hostname 127.0.0.1:9050 -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64)' --max-time 15"

# r/programming のトップ記事
$REDDIT_CURL "https://www.reddit.com/r/programming/top/.json?t=day&limit=30"

# r/technology のトップ記事
$REDDIT_CURL "https://www.reddit.com/r/technology/top/.json?t=day&limit=30"

# r/webdev のトップ記事
$REDDIT_CURL "https://www.reddit.com/r/webdev/top/.json?t=day&limit=20"
```

**注意事項:**
- 429 エラーが返る場合は 5 秒待ってリトライ（最大3回）
- `data.children[].data` から `title`, `url`, `score`, `selftext`, `subreddit` を取得
- `is_self=true` の投稿は `selftext` が本文、`is_self=false` は `url` が外部リンク
- Reddit のスコア（upvotes）が高い記事は面白い・話題性のある記事が多い

### 3. ソース別フィルタリング・スコアリング

**重要: 各ソースから均等に記事を採用すること。特定ソースに偏らない。**

#### 目標件数（ソース別クォータ） — 厳守

**各ソースから最低5件は必ず採用すること。**クォータ未達のソースがある場合、スコアの閾値を下げてでも件数を確保する。

| ソース | 最低件数 | 目標件数 | 備考 |
|--------|---------|---------|------|
| Hacker News | **5件** | 7件 | 英語圏テック全般 |
| Reddit | **5件** | 7件 | r/programming, r/technology, r/webdev |
| Zenn | **5件** | 7件 | 日本語圏テック |
| dev.to | **3件** | 5件 | 英語チュートリアル・体験談 |

合計: **約20〜25件**

**クォータ達成の手順:**
1. 各ソースごとに独立してスコアリング・選定する
2. まず各ソースから最低件数を確保（スコアが低くても採用）
3. 残り枠を全ソース横断でスコア順に埋める
4. 特定ソースが目標の2倍を超えないようバランスを取る

#### Step 1: 一次フィルタリング（タイトル+概要ベース、ソース別）

各ソースごとに独立してスコアリングし、**ソースごとに上位10〜15件**を Step 2 に送る。

- **preliminary_score**（1-10）を付与:
  - AI/LLM/ML 関連: +3
  - プログラミング言語・フレームワーク: +2
  - DevOps/インフラ: +2
  - セキュリティ: +2
  - OSS/開発ツール: +1
  - ユーモア・面白いプロジェクト・変わった使い方: +2
  - コミュニティで話題（HN 100+ pt / Reddit 100+ upvotes / Zenn トレンド）: +1
  - 開発者あるある・失敗談・体験談: +2
- **preliminary_score >= 4 の記事のみ Step 2 に進む**（閾値を下げて候補を多く確保）
- `processed_urls.json` に含まれる URL は除外（重複排除）

#### Step 2: 二次フィルタリング（本文ベース、ソース別）

**ソースごとに独立して**候補記事の本文を取得し詳細にスコアリングする。

本文取得方法:
- **dev.to**: `https://dev.to/api/articles/{id}` の `body_html` フィールド
- **Zenn**: 記事 URL を curl → HTML から本文抽出
- **Hacker News**: 記事 URL を curl → HTML から本文抽出（外部サイト）
- **Reddit**: `selftext` フィールド。外部リンクの場合は URL を curl

本文取得に失敗した場合は Step 1 のスコアをそのまま使用する。

本文を読んだ上で **interest_score**（1-10）を最終決定：
- 記事の技術的な深さ・新規性
- 実用性・コミュニティへのインパクト
- **ユーモア・エンタメ性**（面白いプロジェクト、意外な使い方、開発者あるある）
- 読み物としての面白さ（体験談、失敗談、議論を呼ぶ意見）
- タイトル詐欺（釣りタイトルで中身が薄い）を検出して減点
- **interest_score >= 6 の記事のみ採用**（技術的深さだけでなく面白さも評価）
- **各ソースから目標件数を採用**してから、残り枠を全体スコア順で埋める

### 4. 日本語要約生成

採用した各記事について以下を生成する（本文を読んでいる場合はそれを元に）：
- **title**: 日本語タイトル（原題の意味を保った自然な翻訳）
- **summary**: 3〜5文の日本語要約（記事の要点を簡潔に）
- **tags**: 関連技術タグ（英語、2〜4個）

### 5. ファイル出力

#### 記事ファイル（`content/posts/YYYY-MM-DD.md`）
前日の日付をファイル名・date に使用する。Write ツールで以下の形式の Markdown ファイルを出力：

```yaml
---
title: "YYYY-MM-DD のテックニュース"
date: YYYY-MM-DD  # 前日の日付
articles:
  - title: "日本語タイトル"
    original_title: "Original Title"
    source: "hn"  # hn|zenn|devto|reddit
    url: "https://..."
    summary: "日本語要約文"
    tags: ["AI", "LLM"]
    interest_score: 8
---
```

#### 処理済み URL 更新（`data/processed_urls.json`）
今回処理した記事の URL を既存リストに追加して上書き保存する。
リストが1000件を超えたら古いものから削除する。

## 使用ツール
- **Bash**: curl による API/RSS アクセス、日付取得
- **Read**: processed_urls.json の読み込み、SKILL.md の参照
- **Write**: 記事ファイル、processed_urls.json の書き込み

## 注意事項
- 各 API/RSS は公式エンドポイントのみ使用（スクレイピング禁止）
- 1ソースの失敗で全体を停止しない（部分的な成功でも出力する）
- 記事が0件の場合はファイルを生成しない

## 翻訳品質ルール
- **日本語のみで出力**すること（中国語・韓国語・ロシア語の混入は厳禁）
- 技術用語は原語のまま保持（例: LLM, API, Kubernetes, Docker, React はそのまま）
- カタカナ化は一般的な外来語のみ（例: サーバー, フレームワーク, パフォーマンス）
- 要約は記事の技術的内容を**具体的に**説明すること
  - NG: 「この記事は非常に興味深い内容を扱っています」
  - OK: 「Rustの新しいasync runtimeであるXがtokioと比較して30%のレイテンシ改善を達成した」
- タイトルは原題の意味を保った自然な日本語訳にすること

## 実行方式

本スキルは **Claude Code headless モード** (`claude -p`) で実行される。

- OpenClaw が `scripts/research-tech-news.sh` を呼び出す
- スクリプトが `claude -p` で本スキルの処理フローを実行
- 記事出力後、`scripts/run-daily.sh` で git commit & push
