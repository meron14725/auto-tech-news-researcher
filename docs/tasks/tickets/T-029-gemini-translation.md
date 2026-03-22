# T-029: Gemini 2.5 Flashによる翻訳処理

**ステータス**: ❌ 取り下げ（2026-03-22）— T-030（Claude Code タスク委任）で代替

> Claude Code headless モード（`claude -p`）で記事収集〜翻訳を全委任する方式を採用。
> Gemini API の導入は不要となり、3つ目の LLM プロバイダー追加を回避。
> 詳細は [T-030](T-030-claude-code-delegation.md) を参照。

## 概要（元の計画）
MiniMax M2.5は多言語混在（中国語・韓国語・ロシア語の混入）の傾向があり、日本語翻訳品質に問題がある。翻訳処理のみGemini 2.5 Flashに委任し、品質を向上させる。

## 背景
- T-028で翻訳品質ルールを強化したが、MiniMax M2.5の根本的な多言語混在傾向は解消できなかった
- Gemini 2.5 Flashは日本語生成品質が高く、無料枠もあるため翻訳タスクに適している

## 依存
- T-028（翻訳品質ルール強化）

## やること

### 1. Gemini APIキー取得
- Google AI Studio（https://aistudio.google.com/）でAPIキーを発行
- `~/.openclaw/.env` に `GEMINI_API_KEY=<key>` を追加

### 2. research-trend-news スキル修正
- 記事収集・フィルタリング（Step 1〜3）は MiniMax M2.5 のまま
- 翻訳・要約生成（Step 4）を Gemini 2.5 Flash API を直接 curl で呼び出す方式に変更
- フロー:
  1. MiniMax: 記事収集 → フィルタリング → 採用記事を英語のまま中間JSONに整理
  2. bash で Gemini API を curl → 各記事の日本語タイトル・要約を生成
  3. 結果を組み合わせて `content/posts/YYYY-MM-DD.md` を出力

### 3. Gemini API呼び出し方法
```bash
curl -s "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${GEMINI_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "contents": [{"parts": [{"text": "翻訳プロンプト + 記事データ"}]}]
  }'
```

### 4. 翻訳品質ルール
- T-028 で定義した翻訳品質ルール（中国語禁止、空虚な表現禁止、技術的内容の具体性）をプロンプトに含める
- Gemini の日本語生成品質により、ルール違反は大幅に減少する見込み

### 5. 動作テスト
- 手動実行で記事を生成し、日本語品質を確認

## 完了条件
- 翻訳処理が Gemini 2.5 Flash で実行される
- 生成された記事に中国語・韓国語・ロシア語が混入していない
- 要約が記事の技術的内容を具体的に説明している
- MiniMax のリクエスト消費が翻訳分だけ削減される
