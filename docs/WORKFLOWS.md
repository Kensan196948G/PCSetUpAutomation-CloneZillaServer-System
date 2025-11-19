# 運用ワークフロー

PCキッティング自動化システムの日常的な運用ワークフローを説明します。

## 目次

1. [週次作業](#週次作業)
2. [マスターイメージ作成](#マスターイメージ作成)
3. [大量展開（マルチキャスト）](#大量展開マルチキャスト)
4. [個別展開（ユニキャスト）](#個別展開ユニキャスト)
5. [部署別イメージ管理](#部署別イメージ管理)
6. [トラブル対応](#トラブル対応)

---

## 週次作業

### 毎週月曜日の午前中

```bash
# サーバーにログイン
ssh admin@192.168.100.1

# システム状態確認
./scripts/05-check-status.sh

# ディスク容量確認
df -h /home/partimag

# システム更新確認（セキュリティアップデート）
sudo apt update
sudo apt list --upgradable

# 必要に応じて更新（メンテナンス時間帯に実施）
# sudo apt upgrade -y
```

### 展開履歴の確認

```bash
# 先週の展開履歴を確認
cat /home/partimag/logs/deployment-history.csv | tail -n 20

# エラーログの確認
grep -i "error\|fail" /var/log/clonezilla/*.log | tail -n 20
```

---

## マスターイメージ作成

### 標準的なフロー（約2-3時間）

#### フェーズ1: マスターPC準備（1.5時間）

1. **クリーンインストール**
   ```
   - Windows 10/11をインストール
   - 言語設定: 日本語
   - タイムゾーン: (UTC+09:00) 大阪、札幌、東京
   - ユーザー名: 仮アカウント（後で削除）
   ```

2. **Windows Update**
   ```
   - すべての更新プログラムを適用
   - 再起動を繰り返し、更新がなくなるまで実行
   ```

3. **ドライバーインストール**
   ```
   - メーカー提供の最新ドライバーを適用
   - チップセット、グラフィック、ネットワークなど
   ```

4. **アプリケーションインストール**
   ```
   - Microsoft Office
   - Adobe Acrobat Reader
   - Google Chrome
   - 社内標準ソフトウェア
   - ウイルス対策ソフト
   ```

5. **設定カスタマイズ**
   ```
   - デスクトップ背景（会社ロゴ）
   - 電源設定
   - プライバシー設定
   - Windows Defender設定
   ```

6. **動作確認**
   ```
   - すべてのアプリケーションが起動するか確認
   - ネットワーク接続確認
   - プリンター設定テスト（該当する場合）
   ```

7. **Sysprep実行（推奨）**
   ```batch
   C:\Windows\System32\Sysprep\sysprep.exe /generalize /oobe /shutdown
   ```
   
   **注意事項:**
   - Sysprepを実行すると、PC固有の情報が削除されます
   - Microsoft Storeアプリは一部削除される可能性があります
   - 必ずシャットダウンを選択してください

#### フェーズ2: イメージ作成（0.5-1時間）

1. **サーバー側の準備**

   ```bash
   # イメージ作成スクリプトを実行
   sudo ./scripts/02-create-image.sh win11-dept-sales-$(date +%Y%m)
   ```

2. **Clonezilla設定**

   ブラウザで `http://192.168.100.1:2556` にアクセス:
   
   - Mode: **Beginner**
   - Task: **savedisk**
   - Image name: **win11-dept-sales-202511** (例)
   - Select disk: **sda** (または適切なディスク)
   - Compression: **z1p** (並列gzip圧縮、推奨)
   - Clients: **1** (マスターPC1台)
   
   「Start」をクリック

3. **マスターPCでイメージ作成**

   - マスターPCの電源を入れる（またはシャットダウン後に起動）
   - PXEブートで起動
   - 自動的にClonezillaが起動
   - イメージ作成が開始される
   - 完了するまで待機（通常30-60分）

4. **イメージ確認**

   ```bash
   # イメージ詳細確認
   ./scripts/04-list-images.sh win11-dept-sales-202511
   
   # ファイル整合性確認
   ls -lh /home/partimag/win11-dept-sales-202511/
   cat /home/partimag/win11-dept-sales-202511/disk
   cat /home/partimag/win11-dept-sales-202511/parts
   ```

#### フェーズ3: テスト展開（0.5時間）

1. **テストPCへの展開**

   ```bash
   # 1台だけ展開してテスト
   sudo ./scripts/03-deploy-multicast.sh win11-dept-sales-202511 1 300
   ```

2. **動作確認**

   - Windowsが正常に起動するか
   - すべてのアプリケーションが動作するか
   - ネットワーク接続ができるか
   - ドメイン参加ができるか（該当する場合）

3. **問題があれば修正**

   問題が見つかった場合:
   - マスターPCに戻って修正
   - 再度イメージ作成からやり直し

---

## 大量展開（マルチキャスト）

### 典型的なシナリオ: 新入社員20名分のPC展開

#### 準備（前日）

1. **機材準備**
   ```
   - ターゲットPC 20台
   - ネットワークケーブル 20本
   - 電源タップ
   - ラベル（PC名記入用）
   ```

2. **BIOS設定**
   ```
   各PCで以下を確認:
   - PXE Bootを有効化
   - Boot順序: Network Boot を最優先
   - Secure Bootの設定確認（必要に応じて調整）
   ```

3. **イメージ確認**
   ```bash
   ./scripts/04-list-images.sh win11-new-employee-2025
   ```

#### 当日作業（約2時間）

1. **ネットワーク接続（10分）**
   ```
   - すべてのPCをキッティングネットワークに接続
   - 電源ケーブルを接続（まだ電源は入れない）
   - スイッチのリンクLED確認
   ```

2. **展開開始（5分）**
   ```bash
   # サーバーで展開スクリプトを実行
   sudo ./scripts/03-deploy-multicast.sh win11-new-employee-2025 20 600
   ```
   
   パラメータの意味:
   - イメージ名: `win11-new-employee-2025`
   - 台数: `20`
   - タイムアウト: `600`秒（10分）

3. **ターゲットPC起動（5分）**
   ```
   - すべてのPCの電源を入れる
   - PXEブートが開始されることを確認
   - Clonezilla画面が表示されることを確認
   ```

4. **進捗モニタリング（60-90分）**
   ```bash
   # 別のターミナルでログ確認
   sudo tail -f /var/log/clonezilla/clonezilla-*.log
   
   # ネットワーク使用状況確認
   sudo iftop -i enp0s3
   ```
   
   **正常な進捗の目安:**
   - マルチキャストトラフィック: 400-800 Mbps
   - すべてのクライアントが同期している
   - エラーメッセージがない

5. **完了確認（10分）**
   ```
   - すべてのPCが自動的に再起動
   - Windows起動画面が表示される
   - 初期設定画面（OOBE）が表示される
   ```

#### 事後作業（20分）

1. **PC個別設定**
   ```
   各PCで:
   - コンピューター名設定
   - ドメイン参加（該当する場合）
   - ユーザーアカウント作成
   - ライセンス認証
   ```

2. **動作確認**
   ```
   - ネットワーク接続確認
   - 共有フォルダーアクセス確認
   - プリンター接続確認
   - アプリケーション起動確認
   ```

3. **記録**
   ```bash
   # 展開記録の確認
   cat /home/partimag/logs/deployment-history.csv
   
   # 管理台帳に記録
   - PC名
   - MACアドレス
   - 配布先部署・社員名
   - 展開日時
   ```

---

## 個別展開（ユニキャスト）

### 緊急での1台のみ展開

```bash
# 1台のみ展開（タイムアウトを短く設定）
sudo ./scripts/03-deploy-multicast.sh win11-base-2025 1 120
```

または、Clonezilla SE画面で:
- Mode: **Beginner**
- Task: **restoredisk**
- Image name: 展開するイメージ
- Mode: **Unicast** (1台のみの場合)
- Target disk: **sda**

---

## 部署別イメージ管理

### イメージ命名規則

```
win11-[部署]-[用途]-[年月]

例:
- win11-sales-base-202511      # 営業部基本
- win11-accounting-full-202511 # 経理部フル装備
- win11-engineering-dev-202511 # 開発部開発環境
- win11-general-office-202511  # 一般オフィス用
```

### イメージ構成例

```bash
/home/partimag/
├── win11-sales-base-202511/       # 営業部用
│   └── (Office, CRM, プレゼンツール)
├── win11-accounting-full-202511/  # 経理部用
│   └── (Office, 会計ソフト, Excel強化)
├── win11-engineering-dev-202511/  # 開発部用
│   └── (Visual Studio, Git, Docker)
└── win11-general-office-202511/   # 一般用
    └── (Office, Adobe Reader, Chrome)
```

### 部署別展開フロー

```bash
# 営業部10台
sudo ./scripts/03-deploy-multicast.sh win11-sales-base-202511 10 600

# 経理部5台
sudo ./scripts/03-deploy-multicast.sh win11-accounting-full-202511 5 600

# 開発部15台
sudo ./scripts/03-deploy-multicast.sh win11-engineering-dev-202511 15 600
```

---

## トラブル対応

### よくあるトラブルと対処法

#### 1. PXEブートできないPCがある

**原因:**
- BIOSでPXEブートが無効
- ネットワークケーブルの不良
- スイッチポートの問題

**対処:**
```bash
# DHCPリース確認
cat /var/lib/misc/dnsmasq.leases

# 該当MACアドレスがあるか確認
# なければネットワーク接続の問題
```

#### 2. マルチキャスト展開が遅い

**原因:**
- スイッチがマルチキャストに対応していない
- IGMP Snoopingの設定問題
- ネットワーク帯域不足

**対処:**
```bash
# ネットワーク速度確認
ethtool enp0s3 | grep Speed
# → 1000Mb/s であることを確認

# 台数を減らして再試行
sudo ./scripts/03-deploy-multicast.sh <イメージ名> 10 600
```

#### 3. イメージ復元エラー

**原因:**
- ターゲットディスクのサイズ不足
- ディスク不良
- イメージファイルの破損

**対処:**
```bash
# イメージ整合性確認
ls -lh /home/partimag/<イメージ名>/
# 必須ファイルが揃っているか確認

# ディスクサイズ確認（ターゲットPC）
# マスターPCより大きいディスクが必要
```

---

## ベストプラクティス

### イメージ管理

1. **定期的な更新**
   - 四半期ごとにマスターイメージを更新
   - Windows Update適用後に再作成

2. **世代管理**
   - 最低2世代は保持
   - 古いイメージは別ストレージにバックアップ

3. **命名規則の徹底**
   - 部署-用途-年月 形式を統一
   - README.txtをイメージディレクトリに配置

### 展開作業

1. **事前準備の徹底**
   - チェックリストの作成
   - 機材の事前確認
   - BIOS設定の統一

2. **バッチ処理**
   - 一度に展開する台数は40台まで
   - 50台以上は複数回に分けて実施

3. **記録の徹底**
   - 展開日時、台数、結果を記録
   - 問題があった場合は詳細を記録

---

## 参考資料

- [README.md](../README.md) - システム全体の説明
- [QUICK_START.md](./QUICK_START.md) - クイックスタート
- [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) - トラブルシューティング
