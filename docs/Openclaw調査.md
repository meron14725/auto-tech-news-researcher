# OpenClaw + MiniMax VPS 実現可能性調査

## 結論: 実現可能性は高い

月額 $5〜30 程度で、VPS 上に自律的な AI エージェントプラットフォームを構築できる。

---

## OpenClaw とは

- GitHub 32.7万+ スターの人気 OSS AI エージェント（MIT ライセンス）
- TypeScript 製、Node.js で動作
- 元は「Clawdbot」→「Moltbot」→「OpenClaw」（商標問題で改名）
- 作者: Peter Steinberger（PSPDFKit 創業者）

### できること
- ウェブ閲覧、ファイル読み書き、シェルコマンド実行を自律的に実行
- 20+ チャネル対応（WhatsApp, Telegram, Slack, Discord, LINE 等）
- 会話コンテキストの記憶
- 自分のサーバーで動かせる（セルフホスト、BYOK モデル）
- **Claude Code のオープンソース版に近い存在**

---

## MiniMax LLM 料金

MiniMax は 3 種類の課金体系を提供している。**このプロジェクトでは Token Plan Starter ($10/月) を採用。**

### 料金プラン比較

#### Token Plan（汎用 API）— 採用

OpenClaw など汎用エージェントからの API 呼び出し向け。M2.5 / M2.7 モデルが使える。

| プラン | 月額 | リクエスト上限 | 年額 |
|--------|------|--------------|------|
| **Starter（採用）** | **$10** | **1,500 / 5時間** | $100/年 |
| Plus | $20 | 4,500 / 5時間 | — |
| Max | $50 | 15,000 / 5時間 | — |

- 「リクエスト」= LLM への 1 回の API コール
- 5時間ごとにリクエスト数がリセットされる
- 日次 1 回の記事収集（10〜30 リクエスト）なら Starter で十分余裕

#### Coding Plan（コーディングツール専用）

Claude Code、Kilo Code 等のコーディングツール経由での利用向け。

| プラン | 月額 | プロンプト上限 |
|--------|------|--------------|
| Starter | $10 | 100 / 5時間 |
| Pro | $20 | 詳細不明 |
| Max | $50 | 詳細不明 |

- 「プロンプト」≠「リクエスト」。1 プロンプト = エージェントの 1 指示（内部で 5〜20 API リクエストに分解される）
- モデルは **M2.1 固定**（M2.5 ではない）
- OpenClaw からの汎用利用には使えない

#### Pay-as-you-go（従量課金）

サブスクリプション不要、使った分だけ課金。

| モデル | 入力 $/100万トークン | 出力 $/100万トークン | コンテキスト窓 |
|--------|---------------------|---------------------|---------------|
| **MiniMax M2.5** | $0.20 | $0.95 | 197K |
| MiniMax-01 | $0.20 | $1.10 | 1.0M |
| MiniMax M2.1 | $0.27 | $0.95 | 197K |

日次 1 回の記事収集だけなら月 $1 以下で済むが、OpenClaw で他のタスクも実行する場合は Token Plan の方が予算管理しやすい。

### なぜ Token Plan Starter を選んだか

- 日次記事収集は月 $1 以下だが、OpenClaw で他の自動化タスクも増やしていく予定
- $10/月の固定費で 1,500 リクエスト/5時間は十分な余裕
- Pay-as-you-go と違い使いすぎの心配がない
- 年額 $100 にすれば $20 お得

### 性能ベンチマーク（SWE-bench Verified, 2026年3月時点）

| モデル | スコア | コスト（入力/出力 per 1M tokens） |
|--------|--------|--------------------------------|
| Claude Opus 4.6 | 80.8% | $15 / $75 |
| **MiniMax M2.5** | **80.2%** | **$0.30 / $1.20** |
| Claude Sonnet 4.6 | 79.6% | $3 / $15 |
| DeepSeek V3.2 | 72-74% | $0.14 / $0.28 |

**MiniMax M2.5 は Claude Sonnet 4.6 とほぼ同等の性能を 1/10〜1/20 のコストで実現。**

### 他の安い LLM との比較

| プロバイダ/モデル | 入力 $/100万 | 出力 $/100万 |
|-----------------|-------------|-------------|
| Google Gemini 2.0 Flash-Lite | $0.075 | $0.30 |
| **DeepSeek V3.2** | $0.14 | $0.28 |
| Llama 4 Maverick (ホスト版) | $0.15 | $0.60 |
| **MiniMax M2.5** | $0.20 | $0.95 |
| Claude Sonnet 4.6（参考） | $3.00 | $15.00 |

---

## OpenClaw + MiniMax の互換性

**対応済み。** OpenClaw は OpenAI 互換 API をサポートしており、MiniMax はそれを提供している。

### 接続方法（3つ）
1. **カスタムプロバイダ設定（推奨）** — `models.providers` に MiniMax の `/v1` エンドポイントを直接設定
2. **OpenRouter 経由** — OpenRouter が MiniMax モデルをホスト
3. **OAuth プラグイン** — `minimax-portal-auth` プラグインで認証

---

## VPS 要件

外部 LLM API を使う場合、OpenClaw 自体は軽量（モデルをローカルで動かさないため）。

| リソース | 最低 | 推奨 |
|---------|------|------|
| OS | Ubuntu 22.04 LTS | Ubuntu 22.04 LTS |
| CPU | 2 vCPU | 2〜4 vCPU |
| RAM | 4 GB | 8 GB |
| ストレージ | 20 GB SSD | 40 GB NVMe |
| Node.js | v22.16+ | v24 |

### インストール
```bash
npm install -g openclaw@latest
openclaw onboard --install-daemon
```
Docker もサポート。

### VPS 選択肢

| VPS | スペック | 月額 | 備考 |
|-----|---------|------|------|
| **Oracle Cloud Free Tier** | 4 OCPU / 24GB RAM (ARM) | **無料** | 最安。ただし在庫不足で取得困難な場合あり |
| **Contabo VPS S** | 4 vCPU / 8GB RAM / 200GB NVMe | 〜$6-7 | 安定、OpenClaw 公式でも紹介 |
| ConoHa VPS 2GB | 3 vCPU / 2GB RAM | 〜¥1,848 | 既にアカウントがあるなら手軽 |

**注意**: ConoHa 1GB プラン（現在契約検討中）は RAM 1GB なので OpenClaw には不足。最低 2GB、推奨 4GB 以上。

### セキュリティ
- Gateway は `127.0.0.1` のみにバインド
- 外部アクセスは Cloudflare Tunnel / Tailscale / リバースプロキシ経由

---

## リスクと注意点

| リスク | 詳細 | 対策 |
|--------|------|------|
| **MiniMax レートリミット** | ティアによって TPM/RPM 制限あり | リトライロジックの実装、制限の事前確認 |
| **データ主権** | MiniMax は中国プロバイダ | 機密データを送らない、必要なら DeepSeek や国内 API に切替 |
| **モデル品質** | Claude Sonnet や GPT-5 には及ばない | 自動化タスクには十分、複雑な推論タスクは別モデルを検討 |
| **安全フィルター** | カスタムプロバイダはプロバイダ側のフィルターをスキップ | エージェントのスコープを狭く保つ |
| **プロジェクト体制** | 財団に移行中 | ウォッチ継続 |
| **VPS スペック** | ConoHa 1GB プランでは RAM 不足 | 2GB 以上のプランに変更、または別 VPS |

---

## 推奨構成

### 最安構成（月額 〜$2-5）
- VPS: **Oracle Cloud Free Tier**（無料）
- LLM: **DeepSeek V3.2**（$0.14/$0.28 per 1M tokens）
- 用途: 軽量な自動化、日次タスク

### バランス構成（月額 〜$10-15）
- VPS: **Contabo VPS S**（$6-7/月）
- LLM: **MiniMax M2.5**（$0.20/$0.95 per 1M tokens）
- 用途: 複数チャネル連携、中頻度の自動化

### 既存インフラ活用構成
- VPS: **ConoHa 2GB プラン以上**に変更（〜¥1,848/月）
- LLM: **MiniMax M2.5**
- メリット: 既存の記事収集パイプラインと同居可能（ただし RAM に注意）

---

## このプロジェクトとの関係

現在 ConoHa VPS 1GB で記事収集パイプライン（run-daily.sh）を動かす計画だが、OpenClaw も同居させる場合は **2GB 以上へのアップグレードが必要**。

同居させる場合の構成イメージ:
```
ConoHa VPS (2GB+)
├── auto-tech-news-researcher（既存パイプライン）
│   └── cron → run-daily.sh → claude -p
└── OpenClaw（新規）
    └── MiniMax M2.5 API 連携
    └── 各種自動化タスク
```

---

## VPS 詳細調査

### Oracle Cloud Free Tier（Always Free）

**公式サイト**: https://www.oracle.com/cloud/free/

#### スペック

| インスタンス | CPU | RAM | ストレージ | 月額 |
|-------------|-----|-----|-----------|------|
| **ARM (Ampere A1 Flex)** | 4 OCPU | 24 GB | 200 GB（共有） | **無料** |
| AMD Micro（参考） | 1/8 OCPU × 2台 | 1 GB × 2台 | 上記と共有 | 無料 |

ARM インスタンスが OpenClaw に最適。AMD Micro は RAM 1GB で不足。

#### ネットワーク

| リソース | 制限 |
|---------|------|
| アウトバウンド通信 | **10 GB/月** |
| インバウンド通信 | 無制限 |
| パブリック IPv4 | インスタンス稼働中1つ無料 |

10 GB/月は API コール主体なら十分だが、ウェブサービスを大量配信する場合は注意。

#### サインアップ手順
1. https://www.oracle.com/cloud/free/ → 「Start for free」
2. メール、氏名、**ホームリージョン選択**（⚠️ 後から変更不可）
   - 日本なら **AP-Tokyo-1** または **AP-Osaka-1** を選択
3. メール・電話番号認証
4. クレジットカード登録（本人確認用、課金はされない）
5. 数分〜30分でアカウント開設

#### ⚠️ 最大の問題: ARM インスタンスの在庫不足

**東京・大阪リージョンでは ARM A1 インスタンスが非常に取得しにくい。** `"Out of host capacity"` エラーが頻発する。

**対策**:
- OCI CLI でインスタンス作成を数分おきにリトライするスクリプトを回す（数時間〜数週間かかる場合あり）
- 深夜帯や週末に試すと成功率が上がる
- 大阪の方が東京より取りやすいとの報告あり
- まず小さめ（1 OCPU / 6 GB）で作り、後で拡大する方が成功しやすい

#### アイドルインスタンスの回収リスク

Oracle は低 CPU 使用率のインスタンスを**回収（削除）する場合がある**。cron ジョブや常駐プロセスを動かして「アイドル」と判定されないようにする必要がある。（OpenClaw を常時稼働させていれば問題なし）

#### 課金リスク

- **Free Tier のまま（アップグレードしない）**: 課金リスクゼロ。有料リソースを作れない
- **Pay As You Go にアップグレードした場合**: 間違って有料リソースを作るリスクあり
- **推奨**: アップグレードしない

#### セットアップ手順（ARM Ubuntu）
```bash
# 1. OCI コンソールでインスタンス作成
#    Shape: VM.Standard.A1.Flex / 4 OCPU / 24 GB
#    Image: Ubuntu 22.04 or 24.04 (aarch64)
#    SSH 公開鍵を登録

# 2. SSH 接続
ssh ubuntu@<public_ip>

# 3. Node.js インストール（ARM64 対応）
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
source ~/.bashrc
nvm install 22
node --version

# 4. ⚠️ ファイアウォール設定（2重の壁に注意）
# 壁1: OCI Security List（Web コンソールで設定）
#   VCN → サブネット → Security Lists → Ingress Rule 追加
# 壁2: OS レベルの iptables
sudo iptables -I INPUT 6 -m state --state NEW -p tcp --dport 3000 -j ACCEPT
sudo netfilter-persistent save

# 5. OpenClaw インストール
npm install -g openclaw@latest
openclaw onboard --install-daemon
```

#### 評価

| 項目 | 評価 | 備考 |
|------|------|------|
| スペック | ★★★★★ | 無料で 4 OCPU / 24 GB は破格 |
| コスト | ★★★★★ | 完全無料 |
| 取得難易度 | ★★☆☆☆ | ARM 在庫不足が深刻、数日〜数週間かかる可能性 |
| 安定性 | ★★★☆☆ | アイドル回収リスクあり |
| ネットワーク | ★★★☆☆ | 10 GB/月のアウトバウンド制限 |

---

### Contabo VPS

**公式サイト**: https://contabo.com/en/vps/

#### プラン比較

| プラン | vCPU | RAM | NVMe | 帯域 | 月額（USD） | 月額（JPY 目安） | 初期費用 |
|--------|------|-----|------|------|------------|----------------|---------|
| **VPS S** | 4 | 8 GB | 50 GB | 32 TB | $6.99 | 〜¥1,050 | $6.99 |
| VPS M | 6 | 16 GB | 100 GB | 32 TB | $11.99 | 〜¥1,800 | $6.99 |
| VPS L | 8 | 30 GB | 200 GB | 32 TB | $19.99 | 〜¥3,000 | $6.99 |
| VPS XL | 10 | 60 GB | 300 GB | 32 TB | $34.99 | 〜¥5,250 | $6.99 |

※ 年間契約で初期費用が無料/割引になる場合あり。CPU は共有。

**OpenClaw には VPS S（$6.99/月、8 GB RAM）で十分。**

#### データセンター

| リージョン | ロケーション |
|-----------|------------|
| EU | ニュルンベルク、ミュンヘン、ロンドン |
| US | ニューヨーク、セントルイス、シアトル |
| **APAC** | **東京**、シンガポール、シドニー |

**東京 DC あり。** ただし在庫状況により選択不可の場合あり。その場合はシンガポールが次善。

#### サインアップ手順
1. https://contabo.com/en/vps/ でプラン選択
2. リージョン選択（Tokyo を選ぶ）
3. OS 選択（Ubuntu 22.04 / 24.04）
4. 支払い: クレジットカード / PayPal
5. **本人確認が必要**（写真付き ID の提出を求められる場合あり）
6. プロビジョニング: 確認後 数時間〜1-2営業日

#### ConoHa VPS との比較

| 項目 | Contabo VPS S | ConoHa 4GB プラン |
|------|--------------|-------------------|
| RAM | **8 GB** | 4 GB |
| vCPU | 4 | 4 |
| ストレージ | 50 GB NVMe | 100 GB SSD |
| 帯域 | 32 TB/月 | 無制限 |
| **月額** | **〜¥1,050** | ¥3,091 |
| 東京 DC | あり | あり |
| サポート言語 | 英語/ドイツ語 | **日本語** |
| 支払い | USD/EUR | **JPY** |
| 本人確認 | 遅い（1-2日） | 速い |

**Contabo は ConoHa の約 1/3 の料金で 2 倍の RAM。** コスト重視なら Contabo、日本語サポート・手軽さ重視なら ConoHa。

#### 注意点
- **CPU 性能は共有で変動する**（ピーク時にスロットリングの可能性）。ただし OpenClaw は API コール主体なので影響小
- **サポートは遅い**（12〜48時間）。ライブチャットなし
- **本人確認で 1-3 日かかる場合がある**
- **自動バックアップなし**（有料オプション）

#### 評価

| 項目 | 評価 | 備考 |
|------|------|------|
| スペック | ★★★★☆ | 価格に対して RAM 8GB は優秀 |
| コスト | ★★★★★ | $6.99/月は最安クラス |
| 取得難易度 | ★★★★☆ | 本人確認さえ通れば簡単 |
| 安定性 | ★★★★☆ | CPU 変動あるが実用上問題なし |
| ネットワーク | ★★★★★ | 32 TB/月、東京 DC あり |

---

## 最終比較: どちらを選ぶべきか

| | Oracle Cloud Free | Contabo VPS S |
|---|---|---|
| 月額 | **無料** | $6.99（〜¥1,050） |
| RAM | 24 GB | 8 GB |
| 取得の手軽さ | ❌ 在庫不足で数日〜数週間 | ✅ 1-2日で使える |
| 安定性 | ⚠️ アイドル回収リスク | ✅ 安定 |
| アウトバウンド | 10 GB/月 | 32 TB/月 |
| おすすめ度 | 時間に余裕があり無料にこだわるなら | **すぐ始めたいならこちら** |

**結論**: まず **Contabo VPS S** で始めて、余裕があれば Oracle Cloud Free Tier も並行して取得を試みるのがおすすめ。

---

## Oracle Cloud ARM インスタンス関連の参考記事

### スケーリング・基本情報

- [Changing the Shape of an Instance（公式ドキュメント）](https://docs.oracle.com/en-us/iaas/Content/Compute/Tasks/resizinginstances.htm) — A1.Flex のOCPU/RAM変更手順。インスタンス再起動で変更可能、再作成不要
- [Oracle Cloud Free Tier Guide（GitHub Gist）](https://gist.github.com/rssnyder/51e3cfedd730e7dd5f4a816143b25dbd) — Free Tier の包括的ガイド。OCPU/RAM の分割パターン（1/6, 2/12, 3/18, 4/24）の解説あり
- [Breaking down the free tier of OCI](https://fullmetalbrackets.com/blog/oci-free-tier-breakdown/) — Always Free と試用クレジットの違い、リソース分割の詳細

### 「Out of host capacity」対策・リトライスクリプト

- [Resolving Oracle Cloud "Out of Capacity" issue（Medium）](https://hitrov.medium.com/resolving-oracle-cloud-out-of-capacity-issue-and-getting-free-vps-with-4-arm-cores-24gb-of-a3d7e6a027a8) — 最も有名な対策記事。OCI CLI ベースのリトライ手法
- [hitrov/oci-arm-host-capacity（GitHub, 2k+ stars）](https://github.com/hitrov/oci-arm-host-capacity) — PHP製リトライスクリプト。Telegram/メール通知対応
- [mohankumarpaluru/oracle-freetier-instance-creation（GitHub）](https://github.com/mohankumarpaluru/oracle-freetier-instance-creation) — Python製リトライスクリプト。60秒間隔で自動リトライ
- [futchas/oracle-cloud-free-arm-instance（GitHub）](https://github.com/futchas/oracle-cloud-free-arm-instance) — Bash製の軽量リトライスクリプト

### 日本語記事

- [TerraformでOCIのA1インスタンス無料枠争奪戦を戦う（Zenn）](https://zenn.dev/kotapon/articles/02e245a1655360) — Terraform + シェルスクリプトでのリトライ自動化
- [Oracle Cloudの無料枠をもぎ取る方法（Qiita）](https://qiita.com/pfpfdev/items/c52b0046cd9090efdc64) — 小さいインスタンスから作る、AD を変えるなどの実践テクニック
- [Oracle CloudのAlways FreeのArmは空いていないからAMDにしよう](https://blog.usuyuki.net/oracle_cloud_always_free/) — ARM が取れない現実と AMD 代替案の紹介
- [Oracle Cloud Always Free 枠でArmインスタンスを作る](https://servercan.net/blog/2021/07/oracle-cloud-always-free-%E6%9E%A0%E3%81%A7arm%E3%82%A4%E3%83%B3%E3%82%B9%E3%82%BF%E3%83%B3%E3%82%B9%E3%82%92%E4%BD%9C%E3%82%8B/) — ステップバイステップの作成手順、AD2 選択のコツ
- [OCI Always Freeを使ってタダでMisskeyインスタンスを立てよう](https://hide.ac/articles/csERs-7SU) — 大阪リージョンの方が取りやすいとの報告あり、ファイアウォール設定も詳しい

### 2026年3月時点の最新状況

**Always Free ARM A1 は引き続き提供中。** Oracle 公式ドキュメントでも ARM Compute は Always Free リソースとして記載されている。制度自体は廃止されていない。

**ただし在庫問題は依然として深刻:**
- **東京リージョン（ap-tokyo-1）はほぼ不可能**との報告が複数あり
- **大阪（ap-osaka-1）やシンガポールの方がまだ取りやすい**
- リトライスクリプト（[hitrov/oci-arm-host-capacity](https://github.com/hitrov/oci-arm-host-capacity)）は引き続きメンテナンスされており、Issues ページでも利用報告あり
- 一部情報では **Pay As You Go にアップグレード（無料枠内なら課金なし）すると優先的に容量が割り当てられる**との報告あり

**結論: 仕組みは健在だが、日本リージョンでの取得は依然としてギャンブル。** 数日〜数週間のリトライを覚悟するか、大阪リージョンを選ぶのが現実的。

Sources:
- [Oracle Cloud Always Free Resources（公式）](https://docs.oracle.com/en-us/iaas/Content/FreeTier/freetier_topic-Always_Free_Resources.htm)
- [Oracle Cloud Free Tier（公式）](https://www.oracle.com/cloud/free/)
- [hitrov/oci-arm-host-capacity（GitHub）](https://github.com/hitrov/oci-arm-host-capacity)
- [Oracle Cloud Free Tier Guide 2025](https://topuser.pro/free-oracle-cloud-services-guide-oracle-cloud-free-tier-2025/)
- [OCI Always Free Ampereインスタンスを取る](https://serversmanvps.xn--ockc3f5a.com/2025/03/09/ocialways-free-ampere%E3%82%A4%E3%83%B3%E3%82%B9%E3%82%BF%E3%83%B3%E3%82%B9%E3%82%92%E5%8F%96%E3%82%8B/)
- [Oracle Cloud Compute ARM Free Tier Infographic 2025](https://www.freetiers.com/directory/oracle-cloud-compute-arm)

### ポイントまとめ
- 垂直スケールは可能（停止→シェイプ変更→起動）
- 大阪の方が東京より取りやすい傾向
- 1 OCPU / 6 GB から始めて後で拡大する戦略が有効
- リトライスクリプトは必須（数時間〜数週間かかる覚悟）
- Pay As You Go にアップグレードすると取得しやすくなるとの報告あり（無料枠内なら課金されない）

---

## 参考リンク
- [OpenClaw GitHub](https://github.com/openclaw/openclaw)
- [OpenClaw ドキュメント](https://docs.openclaw.ai/)
- [OpenClaw VPS セットアップガイド](https://docs.openclaw.ai/vps)
- [MiniMax API 料金](https://platform.minimax.io/docs/pricing/overview)
- [Oracle Cloud Free Tier サインアップ](https://www.oracle.com/cloud/free/)
- [Oracle Cloud Always Free ドキュメント](https://docs.oracle.com/en-us/iaas/Content/FreeTier/freetier_topic-Always_Free_Resources.htm)
- [Contabo VPS 料金ページ](https://contabo.com/en/vps/)
- [Contabo OpenClaw ホスティング](https://contabo.com/en/openclaw-hosting/)
