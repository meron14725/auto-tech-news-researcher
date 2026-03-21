# T-028: 翻訳専門サブエージェントの導入

## 概要
`research-trend-news` スキルの日本語要約品質が低い（中国語混入、空虚な表現、不自然な体言止め）ため、翻訳タスクを専門のサブエージェントに分離する。

## 背景
1つのエージェントが記事収集・フィルタリング・翻訳を全て担当しており、翻訳品質に十分な注意が払われていない。
OpenClaw の `sessions_spawn` を使い、翻訳専門のサブエージェントを起動して品質を向上させる。

## 依存
- T-014.5（OpenClaw スキル変換）

## やること

### 1. `translate-tech-news` スキル新規作成
- `~/.openclaw/skills/translate-tech-news/SKILL.md` を作成
- 入力: 中間 JSON（英語の記事データ）
- 出力: `content/posts/YYYY-MM-DD.md`（YAML front matter 形式）
- 翻訳品質ルールを集約:
  - 中国語の漢字混入禁止
  - HN ポイント数などメタ情報を要約に含めない
  - 「注目を集めている」「話題沸騰中」のような空虚な表現を禁止
  - 具体的な技術内容を要約する
  - 良い例・悪い例を明記
- `processed_urls.json` の更新もここで行う

### 2. `research-trend-news` スキル修正
- Step 1〜3（収集・フィルタリング）後に中間 JSON を `/tmp/trend-news-raw-YYYY-MM-DD.json` に出力
- `sessions_spawn` で翻訳サブエージェントを起動し、中間 JSON パスを渡す
- サブエージェント完了後に `run-daily.sh` を実行

### 3. 中間 JSON フォーマット定義
```json
{
  "date": "2026-03-21",
  "articles": [
    {
      "original_title": "Original Title",
      "source": "hn",
      "url": "https://...",
      "body_excerpt": "First 500 chars of article body...",
      "tags": ["AI", "LLM"],
      "interest_score": 8
    }
  ]
}
```

### 4. 動作テスト
- 手動実行で記事を生成し、日本語品質を確認

## 完了条件
- `translate-tech-news` スキルが OpenClaw に認識されている
- `research-trend-news` スキルが `sessions_spawn` で翻訳サブエージェントを起動する
- 生成された記事の日本語に中国語が混入していない
- 要約が記事の技術的内容を具体的に説明している
