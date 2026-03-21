# フィードバックループ アーキテクチャ

## 全体アーキテクチャ図

![アーキテクチャ図](architecture.svg)

## 概要

ユーザーがサイト上で記事を👍👎評価し、そのフィードバックをもとに記事収集スキル（SKILL.md）を自動改善する仕組み。

## データフロー

```
[毎日 JST 9:15]
OpenClaw cron → エージェント → SKILL.md 実行 → 記事収集・要約 → YYYY-MM-DD.md
    ↓ run-daily.sh (git push)
    ↓ Cloudflare Pages 自動ビルド
[Hugo サイト公開]
    ↓ ユーザーが閲覧・評価
[ブラウザ] → 👍👎ボタン → POST /api/feedback
    ↓
[Cloudflare Pages Function: functions/api/feedback.js]
    ↓ バリデーション → 保存
[Cloudflare KV: ARTICLE_FEEDBACK]
    ↓
[2日ごと JST 23:00]
OpenClaw cron → エージェント
    ├── scripts/fetch-feedback.sh → KV API で直近2日分取得 → data/feedback.json
    └── feedback.json + SKILL.md 分析 → SKILL.md 改善
    ↓
run-improve.sh (git commit & push) → 次の記事収集に反映
```

## コンポーネント詳細

### 1. フィードバック API

**エンドポイント**: `POST /api/feedback`

**リクエスト**:
```json
{
  "date": "2026-03-14",
  "url": "https://example.com/article1",
  "rating": "good",
  "source": "hn",
  "interest_score": 8
}
```

**レスポンス**:
- `200`: `{"status": "ok"}`
- `400`: `{"status": "error", "message": "Invalid rating value"}`
- `429`: `{"status": "error", "message": "Rate limited"}`

**実装**: `functions/api/feedback.js`（Cloudflare Pages Function）

### 2. Cloudflare KV スキーマ

**ネームスペース**: `ARTICLE_FEEDBACK`

**キー形式**: `{YYYY-MM-DD}::{article_url}`
- `::` をセパレータに使用（URL に含まれる `:` `/` との混同を避けるため）
- 日付プレフィックスで特定日のフィードバックを効率的に一括取得可能

**値**:
```json
{
  "rating": "good",
  "timestamp": "2026-03-15T10:30:00Z",
  "source": "hn",
  "interest_score": 8
}
```

**TTL**: 90日（古いフィードバックは自動削除）

### 3. フィードバック取得・変換

**スクリプト**: `scripts/fetch-feedback.sh`

**出力**: `data/feedback.json`
```json
{
  "skill": "research-trend-news",
  "collected_at": "2026-03-15",
  "period": { "from": "2026-03-13", "to": "2026-03-15" },
  "ratings": [
    {
      "date": "2026-03-14",
      "url": "https://example.com/article1",
      "source": "hn",
      "interest_score": 8,
      "rating": "good"
    }
  ],
  "summary": {
    "total": 12,
    "good": 8,
    "bad": 4,
    "good_rate": 0.67,
    "by_source": {
      "hn": { "good": 4, "bad": 1 },
      "devto": { "good": 2, "bad": 2 },
      "zenn": { "good": 2, "bad": 1 }
    },
    "by_score": {
      "7": { "good": 2, "bad": 3 },
      "8": { "good": 3, "bad": 1 },
      "9": { "good": 3, "bad": 0 }
    }
  }
}
```

**環境変数**:
- `CF_ACCOUNT_ID`: Cloudflare アカウント ID
- `CF_KV_NAMESPACE_ID`: KV ネームスペース ID
- `CF_API_TOKEN`: KV 読み書き権限のある API トークン

### 4. スキル改善スクリプト

**スクリプト**: `scripts/run-improve.sh`

**処理フロー**:
1. `git pull origin main`
2. `scripts/fetch-feedback.sh` 実行
3. feedback.json のレーティング数チェック（5件未満ならスキップ）
4. `claude -p` で skill-creator にフィードバック分析・SKILL.md 改善を指示
5. SKILL.md のみ変更されていることを確認（安全策）
6. `git commit & push`

**cron スケジュール**: `0 23 */2 * * /path/to/scripts/run-improve.sh`

### 5. フィードバック UI

**場所**: `layouts/posts/single.html` の各記事カード内

**動作**:
- 👍👎ボタンをクリック → `/api/feedback` に POST
- localStorage に投票状態を保存（ブラウザ再読み込みでも状態維持）
- 投票済みボタンをハイライト表示

## 設計判断

| 判断 | 理由 |
|------|------|
| Pages Function を使用（standalone Worker ではなく） | Pages と同じプロジェクトで管理、追加のルーティング設定不要 |
| ユーザー認証なし | 自分専用サイト、localStorage + レートリミットで十分 |
| 2日ごとに改善 | 毎日ではフィードバックが不十分、2日で蓄積してから改善 |
| SKILL.md のみ変更許可 | 改善スクリプトが他ファイルを書き換えるリスクを防止 |
| feedback.json に集計サマリ付与 | AI のターン数を節約、構造化データで精度の高い分析が可能 |
