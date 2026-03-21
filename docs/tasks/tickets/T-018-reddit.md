# T-018: Reddit OAuth2 認証 + 記事取得機能

## 概要
Reddit の REST API を OAuth2 認証で利用し、プログラミング関連サブレディットからトレンド記事を取得する（Phase 2）。

## やること
- Reddit App の作成（script type）
- OAuth2 認証フローの実装（Client Credentials）
- `/r/programming/top?t=day` 等からトップ記事を取得
- 認証情報（client_id, client_secret）のセキュアな管理
- 取得した記事データを共通フォーマットに変換

## 参考
- API: `https://oauth.reddit.com/`
- 認証: OAuth2 必須

## 完了条件
- OAuth2 トークンの取得が自動化されている
- Reddit の記事が取得・処理される
- 認証情報がリポジトリに含まれていない
