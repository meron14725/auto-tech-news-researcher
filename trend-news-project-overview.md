# 自動トレンドニュースサイト — プロジェクト概要

## 実現したいこと

テック系（プログラミング、AI、インフラ、OSSなど）のトレンドニュースを毎日自動で収集し、日本語で要約して自分のWebサイトに公開する。人手を一切介さず、毎朝サイトを開けば最新のニュースが並んでいる状態を目指す。

---

## 背景・モチベーション

- Zenn、Reddit、Hacker News、dev.to、Qiita など複数のソースに散らばるテック情報を、一箇所に集約して効率よくキャッチアップしたい
- Claude の Max 5x サブスク（$100/月）を既に契約しており、Claude Code CLI をサブスク枠内で活用したい（追加API料金なし）
- クラウドサーバー（VPS）を使ってみたいという学習意欲がある
- できるだけ低コストで運用したい

---

## 要件定義

### 機能要件

| # | 要件 | 詳細 |
|---|------|------|
| F-1 | トレンドニュースの自動収集 | Zenn RSS、Hacker News API、Reddit API、dev.to API、Qiita RSS から毎日取得 |
| F-2 | AIによるフィルタリング | Claude Code CLI（スキル機能）で記事の重要度をスコアリングし、interest_score 7以上のみ採用 |
| F-3 | 日本語要約の自動生成 | 各記事に日本語タイトルと3〜5文の要約を生成 |
| F-4 | JSON形式での記事保存 | content/posts/YYYY-MM-DD.json としてGitリポジトリに保存 |
| F-5 | 重複排除 | processed_urls.json でURL管理し、過去に処理済みの記事はスキップ |
| F-6 | Webサイトへの自動反映 | git push をトリガーに静的サイトが自動ビルド＆デプロイされる |
| F-7 | 毎日定時に自動実行 | cron で毎日 JST 9:15 に起動（手動実行も可能） |

### 非機能要件

| # | 要件 | 詳細 |
|---|------|------|
| NF-1 | 月額コスト | 1,000円以下を目標（結果: 763円/月） |
| NF-2 | 追加API料金なし | Claude Max 5x サブスク枠内で運用。従量課金APIは使わない |
| NF-3 | 契約の柔軟性 | 長期縛りなし。合わなければ1ヶ月でやめられる |
| NF-4 | 記事データの永続性 | JSONが増え続けても無料枠内で運用可能。ローテーション不要 |
| NF-5 | ブランチ運用 | mainから都度ブランチを切り、PRで統合する |

---

## 検討・意思決定の経緯

### 1. Claude Code CLI vs Anthropic API 直接呼び出し

**結論: Claude Code CLI を採用**

- Max 5x サブスクを既に契約しているため、サブスク枠内で使える Claude Code CLI の方がコスト面で有利
- API直接呼び出しだと別途従量課金（Sonnet: 約$3〜5/月）が発生する
- Skills 機能（CLAUDE.md + SKILL.md）でタスクをモジュール化でき、保守性が高い
- VPS上で `claude -p` コマンドで非対話実行し、`--allowedTools` で権限制御する

### 2. VPS常駐型 vs GitHub Actions型

**結論: VPS常駐型（方式A）を採用**

| 比較軸 | VPS常駐型 | GitHub Actions型 |
|--------|----------|-----------------|
| コスト | 月763円 | 無料 |
| 認証の安定性 | setup-token を環境変数にセット。安定 | 非対話モードでOAuthリフレッシュ失敗のバグ報告あり |
| 実行タイミング | cron で正確 | 5〜30分の遅延が常態 |
| デバッグ | SSHで直接確認、ログをリアルタイムで見れる | Actions UIのログのみ。トライ&エラーが遅い |
| ファイル永続化 | ローカルに自然に残る | 毎回クリーン環境。状態管理に工夫が必要 |
| サーバー管理 | OS更新・セキュリティが自己責任 | 管理不要 |

VPSを使ってみたいという学習目的、デバッグのしやすさ、認証の安定性を重視して方式Aに決定。

### 3. VPSの選定

**結論: ConoHa VPS 1GBプラン（まとめトク1ヶ月 763円）**

選定条件:
- 1ヶ月契約ができること（長期縛りなし）
- 初期費用が無料であること
- メモリ1GB以上（Claude Code CLI = Node.js が動く最低ライン）

最終候補4社の比較:

| VPS | 月額 | メモリ | CPU | SSD | 選定理由 |
|-----|------|--------|-----|-----|----------|
| **ConoHa VPS** | **763円** | **1GB** | **2コア** | **100GB** | **← 採用。スペックが価格に対して最も充実** |
| KAGOYA CLOUD | 550円 | 1GB | 1コア | 25GB | 最安・縛りなしだがSSD 25GBと少ない |
| WebARENA Indigo | 449円 | 1GB | 1コア | 20GB | 最安級だが機能が最小限、スケールアップ不可 |
| さくらVPS | 643円 | 512MB | 1コア | 25GB | メモリ512MBではClaude Code CLIがギリギリ |

ConoHaは213円高いが、CPUが2倍（2コア）、SSDが4倍（100GB）。将来的に他の用途にも流用できるプラットフォームとして投資対効果が高い。

### 4. ホスティングの選定

**結論: Cloudflare Pages（無料）**

| 項目 | Cloudflare Pages | GitHub Pages | Vercel | Netlify |
|------|-----------------|-------------|--------|---------|
| 帯域幅 | **無制限** | 100GB/月 | 100GB/月 | ~30GB/月 |
| ビルド上限 | 500回/月 | 10回/時 | 制限なし | クレジット制 |
| 商用利用 | ✅ | ❌ | ❌ | ✅ |
| ファイル上限 | 20,000 | - | - | - |

帯域幅無制限かつ商用利用OKでCloudflare Pagesに決定。1日1回デプロイ（月30回）なので500回/月のビルド上限にも余裕がある。

### 5. SSG（静的サイトジェネレーター）の選定

**結論: Hugo**

- Go製シングルバイナリで依存関係が少なく、VPS・CI両方でセットアップが簡単
- ビルド速度がSSG最速（1,000ページ約2秒）。記事が自動で増え続けるユースケースに最適
- Markdownネイティブ対応、300以上のテーマ
- Astroも候補だったが、Node.js依存がある分セットアップが重い

### 6. データ蓄積の持続可能性

**結論: ローテーション不要。増え続けても無料枠内**

- 1記事JSON ≈ 2〜5KB。1日1記事で年間1〜2MB
- GitHubリポジトリ推奨上限1GB → 250年以上余裕
- Cloudflare Pages 無料枠 20,000ファイル → 1日1記事で54年分
- Cloudflare Pages 帯域幅無制限
- 万が一将来ファイル数が増えすぎたら、古い記事をアーカイブリポジトリに移す運用で対処可能

---

## 基本構成

### アーキテクチャ図

```
┌─────────────────────────────────────────────┐
│  ConoHa VPS (Ubuntu 24.04)                  │
│  1GB RAM / 2コア / 100GB SSD                │
│                                             │
│  cron (毎日 JST 9:15)                       │
│    └── scripts/run-daily.sh                 │
│          └── claude -p "/research-trend-news │
│               スキルを実行して"              │
│               --allowedTools ...             │
│               --max-turns 20                │
│                                             │
│  Claude Code CLI                            │
│    ├── CLAUDE.md (プロジェクト指示書)        │
│    └── .claude/skills/                      │
│        └── research-trend-news/SKILL.md     │
│                                             │
│  認証: CLAUDE_CODE_OAUTH_TOKEN              │
│        (setup-token で発行、1年有効)         │
└──────────────┬──────────────────────────────┘
               │ git push
               ▼
┌─────────────────────────────────────────────┐
│  GitHub リポジトリ (public)                  │
│                                             │
│  content/posts/                             │
│    ├── 2026-03-15.json                      │
│    ├── 2026-03-16.json                      │
│    └── ...                                  │
│  data/processed_urls.json                   │
│  hugo.toml / layouts/ / themes/             │
└──────────────┬──────────────────────────────┘
               │ push を検知
               ▼
┌─────────────────────────────────────────────┐
│  Cloudflare Pages (無料)                     │
│                                             │
│  Hugo ビルド → CDN 配信                     │
│  https://trend-news.pages.dev               │
└─────────────────────────────────────────────┘
```

### パイプラインフロー

```
1. cron 発火 (毎日 JST 9:15)
2. run-daily.sh 起動
3. git pull origin main (最新コード取得)
4. claude -p でスキル実行
   4-1. RSS/API からニュース取得 (curl)
   4-2. processed_urls.json と照合 (重複スキップ)
   4-3. フィルタリング + スコアリング
   4-4. 日本語タイトル・要約を生成
   4-5. YYYY-MM-DD.json を生成
   4-6. processed_urls.json を更新
5. git add → commit → push
6. Cloudflare Pages が検知 → Hugo ビルド → デプロイ
7. サイトに新しい記事が反映される
```

### ニュースソース

| ソース | 取得方法 | 認証 | 特徴 |
|--------|----------|------|------|
| Hacker News | Firebase API | 不要 | 認証不要・レート制限なし。最も扱いやすい |
| Zenn | RSS (`/feed`) | 不要 | 日本語テック記事のトレンド |
| dev.to | REST API | 不要（GET） | 英語圏のテック記事。APIが素直 |
| Qiita | RSS (`/popular-items/feed.atom`) | 不要 | 日本語テック記事。ストック数ベースの人気記事 |
| Reddit | REST API | OAuth2必須 | `/r/programming/top?t=day` 等。実装コストは高め |

初期実装では Hacker News + Zenn + dev.to の3ソースで始め、安定したら Qiita・Reddit を追加する方針。

### 記事JSONスキーマ

```json
{
  "date": "2026-03-15",
  "articles": [
    {
      "title": "日本語タイトル",
      "original_title": "Original English Title",
      "source": "hn",
      "url": "https://example.com/article",
      "summary": "日本語で3〜5文の要約。元記事の内容を簡潔にまとめる。",
      "tags": ["AI", "LLM", "OSS"],
      "interest_score": 8
    }
  ]
}
```

### ブランチ運用

```
main (本番ブランチ — Cloudflare Pages が監視)
  ├── feature/initial-setup      (初期構築)
  ├── feature/hugo-theme         (テーマ設定)
  ├── feature/skill-definition   (スキル定義)
  ├── feature/cron-setup         (cron設定)
  └── fix/xxx                    (バグ修正)
```

すべての変更はブランチを切ってPRで統合する。自動生成される記事JSONのcommit（cron実行分）のみ、run-daily.sh が直接 main に push する。

---

## コスト

| 項目 | 月額 | 備考 |
|------|------|------|
| ConoHa VPS 1GBプラン | 763円 | まとめトク1ヶ月。初期費用無料 |
| Claude Max 5x | 既存サブスク | 追加料金なし。Usage Limitは5h/50〜200プロンプト |
| GitHub (public repo) | 0円 | |
| Cloudflare Pages | 0円 | 帯域幅無制限、月500ビルドまで |
| **合計** | **763円/月** | |

---

## リスク・注意点

| リスク | 影響 | 対策 |
|--------|------|------|
| OAuthトークンのCI/CD利用がAnthropicの利用規約グレーゾーン | 最悪の場合トークン無効化 | 公式CLIを公式の方法で使っているだけなので低リスク。動向は注視 |
| Claude Max 5x のUsage Limit | 普段のclaude.ai利用枠を圧迫 | 1日1回・数プロンプトなので影響は軽微。5時間ごとにリセット |
| setup-token の期限切れ（1年後） | パイプライン停止 | カレンダーリマインダーを設定し、期限前にローカルPCで再発行 |
| ConoHa VPS のセキュリティ | 不正アクセス | SSH鍵認証のみ許可、UFW有効化、定期的なapt upgrade |
| ニュースソースのAPI変更・停止 | 記事取得失敗 | エラーハンドリングで1ソース障害時も他ソースで継続。ログで検知 |
| スクレイピングの法的リスク | 利用規約違反 | 全ソースで公式API/RSSのみ使用。スクレイピングは行わない |

---

## 今後の拡張案

- Reddit OAuth2 対応による情報ソース追加
- タグ別・ソース別のフィルタリングページ
- RSSフィード配信（サイト自体がRSSを出す）
- Slack/Discord への通知連携
- 記事のサムネイル自動生成
- 週次まとめ記事の自動生成
- 多言語対応（英語サマリーも併記）
