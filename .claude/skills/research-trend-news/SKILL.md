# research-trend-news

技術トレンドニュースを複数ソースから収集し、日本語で要約して記事ファイルを生成するスキル。

## 処理フロー

### 1. 準備
- 前日の日付を取得（`date -d yesterday +%Y-%m-%d`、macOS では `date -v-1d +%Y-%m-%d`）
- `data/processed_urls.json` を読み込み、処理済み URL リストを取得
- 既に `content/posts/{前日の日付}.md` が存在する場合は処理をスキップ

### 2. 記事取得

以下のソースから記事を取得する。各ソースで取得に失敗しても他のソースの処理は続行する。

#### Hacker News（Firebase API）
```bash
# トップ30記事のIDを取得
curl -s "https://hacker-news.firebaseio.com/v0/topstories.json" | head -c 500

# 各記事の詳細を取得（上位30件）
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

### 3. 2段階フィルタリング・スコアリング

#### Step 1: 一次フィルタリング（タイトル+概要ベース）

取得した全記事（〜30件×3ソース）をタイトルと概要（description）で粗くスコアリングする：

- **preliminary_score**（1-10）を付与:
  - AI/LLM/ML 関連: +3
  - プログラミング言語・フレームワーク: +2
  - DevOps/インフラ: +2
  - セキュリティ: +2
  - OSS/開発ツール: +1
  - HN での高ポイント（100+）: +1
  - Zenn でのトレンド入り: +1
- **preliminary_score >= 5 の記事のみ Step 2 に進む**
- `processed_urls.json` に含まれる URL は除外（重複排除）

#### Step 2: 二次フィルタリング（本文ベース）

Step 1 を通過した候補記事（〜10件程度）について、記事本文を取得して詳細にスコアリングする。

本文取得方法:
- **dev.to**: `https://dev.to/api/articles/{id}` の `body_html` フィールド
- **Zenn**: 記事 URL を curl → HTML から本文抽出
- **Hacker News**: 記事 URL を curl → HTML から本文抽出（外部サイト）

本文取得に失敗した場合は Step 1 のスコアをそのまま使用する。

本文を読んだ上で **interest_score**（1-10）を最終決定：
- 記事の技術的な深さ・新規性を評価
- 実用性・コミュニティへのインパクトを考慮
- タイトル詐欺（釣りタイトルで中身が薄い）を検出して減点
- **interest_score >= 7 の記事のみ採用**
- 最終的に **最大15件** に絞り込む

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
    source: "hn"
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
- **Read**: processed_urls.json の読み込み
- **Write**: 記事ファイル、processed_urls.json の書き込み

## 注意事項
- 各 API/RSS は公式エンドポイントのみ使用（スクレイピング禁止）
- 1ソースの失敗で全体を停止しない（部分的な成功でも出力する）
- 記事が0件の場合はファイルを生成しない
