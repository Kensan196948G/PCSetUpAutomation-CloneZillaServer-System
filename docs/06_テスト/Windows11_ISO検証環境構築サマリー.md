# Windows11.iso検証環境構築サマリー

**作成日**: 2025-11-17
**対象ISO**: `/mnt/Linux-ExHDD/PCSetUpAutomation-CloneZillaServer-Project/media/Windows11.iso` (5.7GB)

---

## 作成完了ファイル一覧

### 1. スクリプト（scripts/）

#### `/scripts/validate-windows-iso.sh`
**サイズ**: 12KB
**実行権限**: 付与済み

**概要**:
Windows11.isoファイルの自動検証スクリプト。以下のチェックを実行：
- ISOファイル存在確認
- ファイルサイズチェック（5GB以上）
- ファイルタイプ確認（ISO 9660）
- SHA256チェックサム計算
- ISOマウントテスト
- Windows 11バージョン情報抽出（wiminfo使用）
- 必須ファイル・フォルダ確認（sources, boot, efi, bootmgr, setup.exe）
- 検証結果レポート自動生成

**使用方法**:
```bash
cd /mnt/Linux-ExHDD/PCSetUpAutomation-CloneZillaServer-Project
./scripts/validate-windows-iso.sh
```

**出力**:
- 標準出力: カラー付き検証ログ
- ファイル出力: `iso_validation_report_YYYYMMDD_HHMMSS.txt`

---

#### `/scripts/setup-test-vm.sh`
**サイズ**: 12KB
**実行権限**: 付与済み

**概要**:
VirtualBox仮想マシン自動作成スクリプト。Windows 11要件を満たすVM構成：
- VM名: 指定可能（デフォルト: `Win11-Test-YYYYMMDDHHMMSS`）
- メモリ: 8GB
- CPU: 2コア
- ディスク: 64GB（VDI形式）
- UEFI/セキュアブート/TPM 2.0有効化
- ISOイメージ自動アタッチ
- ネットワーク: NAT
- クリップボード/ドラッグ&ドロップ有効化

**使用方法**:
```bash
# デフォルト設定でVM作成
./scripts/setup-test-vm.sh

# VM名とISOパスを指定
./scripts/setup-test-vm.sh Win11-Test /path/to/Windows11.iso
```

**対話型機能**:
- 既存VM重複時の削除確認
- 作成後の起動確認

---

### 2. ドキュメント（docs/）

#### `/docs/運用管理/マスターイメージ作成ガイド.md`
**サイズ**: 15KB

**目次**:
1. 概要
2. 事前準備
3. Windows 11インストール手順
4. 会社標準アプリケーション導入
5. Sysprep実行前チェックリスト
6. Sysprep実行手順
7. Clonezillaイメージ化手順
8. マスターイメージ更新時の注意事項
9. トラブルシューティング

**主要内容**:
- BIOS/UEFI設定手順
- Windows 11インストール詳細手順
- AppX削除スクリプト（Sysprep成功率向上）
- 会社標準アプリケーション導入リスト（Microsoft 365, Chrome, Adobe等）
- Sysprep実行コマンドとパラメータ説明
- Clonezillaイメージ作成オプション（圧縮レベル等）
- マスターイメージバージョン管理戦略
- 一般的なSysprep/Clonezillaエラーの解決策

---

#### `/docs/テスト/ISO検証手順書.md`
**サイズ**: 15KB

**目次**:
1. 概要
2. 自動検証スクリプト実行
3. 手動検証手順
4. チェックサム確認手順
5. VMwareでのテストインストール
6. VirtualBoxでのテストインストール
7. 検証チェックリスト
8. トラブルシューティング

**主要内容**:
- `validate-windows-iso.sh` 使用方法
- wimtoolsインストール手順
- ISOマウント/WIMイメージ情報抽出方法
- SHA256ハッシュ計算とMicrosoft公式ハッシュとの比較
- VMware Workstation VM作成手順（TPM/セキュアブート設定含む）
- VirtualBox VM作成コマンドライン例
- 検証チェックリスト（ISO整合性・VMインストールテスト）
- トラブルシューティング（マウント失敗、TPMエラー等）

---

### 3. 設定ファイル（configs/）

#### `/configs/sysprep/unattend.xml`
**サイズ**: 12KB

**概要**:
Windows 11 Sysprep実行時の自動応答ファイル（XML形式）

**主要設定**:

| 設定項目 | 内容 |
|---------|------|
| **言語・地域** | 日本語（ja-JP）、日本標準時（Tokyo Standard Time） |
| **自動ログオンアカウント** | ユーザー名: `SetupAdmin`、パスワード: `TempPass123!` |
| **自動ログオン回数** | 3回（FirstLogonCommands実行用） |
| **OOBE設定** | EULA/ネットワーク/Microsoftアカウント画面をスキップ |
| **FirstLogonCommands** | PowerShell実行ポリシー変更 → 自動セットアップスクリプト実行 → タスクスケジューラ登録 |

**FirstLogonCommandsの実行順序**:
1. `Set-ExecutionPolicy Bypass`（PowerShell実行許可）
2. ログ開始（`C:\AutoSetup\setup.log`）
3. `C:\AutoSetup\setup.ps1` 実行
4. タスクスケジューラ登録（再起動後処理用）
5. ログ完了

**カスタマイズポイント**:
- 管理者アカウント名・パスワード変更
- プロダクトキー設定（ボリュームライセンス）
- タイムゾーン変更
- FirstLogonCommandsへの独自コマンド追加

---

#### `/configs/sysprep/README.md`
**サイズ**: 7.7KB

**概要**:
unattend.xml使用ガイド

**内容**:
- unattend.xmlの役割説明
- マスターPC構築時の配置方法
- Sysprep実行コマンド
- カスタマイズ方法（パスワードBase64エンコード、プロダクトキー設定等）
- 自動実行されるスクリプト仕様（`setup.ps1`, `post-reboot.ps1`）
- トラブルシューティング（XML構文エラー、スクリプト未実行等）
- セキュリティ考慮事項（パスワード管理、自動ログオン無効化）

---

## クイックスタートガイド

### ステップ1: ISOファイル検証

```bash
cd /mnt/Linux-ExHDD/PCSetUpAutomation-CloneZillaServer-Project
./scripts/validate-windows-iso.sh
```

**期待される結果**:
```
[SUCCESS] 検証完了: ISOファイルは正常です
統計: PASS=15, FAIL=0, WARN=0, INFO=2
```

### ステップ2: 仮想環境でテストインストール

```bash
# VirtualBox VMを自動作成
./scripts/setup-test-vm.sh Win11-Sysprep-Test

# VMが起動したらWindows 11をインストール
```

### ステップ3: マスターイメージ作成

**参照ドキュメント**: `/docs/運用管理/マスターイメージ作成ガイド.md`

1. Windows 11インストール
2. 会社標準アプリケーション導入
3. AppX削除スクリプト実行
4. unattend.xml配置
5. Sysprep実行
6. Clonezillaイメージ化

### ステップ4: 自動セットアップスクリプト準備

```powershell
# マスターPC上で実行
New-Item -Path "C:\AutoSetup" -ItemType Directory -Force
Copy-Item -Path "\\fileserver\scripts\setup.ps1" -Destination "C:\AutoSetup\setup.ps1"
Copy-Item -Path "configs/sysprep/unattend.xml" -Destination "C:\Windows\System32\Sysprep\unattend.xml"
```

---

## 必須ツール

### Linux環境（Ubuntu推奨）

```bash
# ISO検証用ツール
sudo apt update
sudo apt install -y wimtools fuseiso bc

# VirtualBox（仮想マシン作成用）
sudo apt install -y virtualbox virtualbox-ext-pack
```

### 確認コマンド

```bash
# VirtualBoxバージョン確認
VBoxManage --version

# wimtoolsインストール確認
wiminfo --version
```

---

## 検証チェックリスト

### ISO検証

- [ ] `validate-windows-iso.sh` 実行完了（PASS）
- [ ] SHA256チェックサム記録
- [ ] ISOマウント成功
- [ ] install.wim存在確認
- [ ] 検証レポート保存

### 仮想環境テスト

- [ ] VirtualBox VM作成成功
- [ ] Windows 11インストール完了
- [ ] デスクトップ到達確認
- [ ] VMスナップショット作成

### Sysprep/unattend.xml

- [ ] unattend.xml配置完了
- [ ] Sysprep実行成功（エラーログなし）
- [ ] 初回起動時の自動ログオン確認
- [ ] FirstLogonCommands実行確認（setup.log確認）

### Clonezillaイメージ化

- [ ] Clonezillaイメージ作成完了
- [ ] イメージ整合性チェック実施
- [ ] DRBLサーバへ転送完了
- [ ] イメージ展開テスト成功

---

## トラブルシューティング早見表

| 症状 | 原因 | 解決策 |
|------|------|--------|
| **ISO検証: mount失敗** | sudo権限不足 | `sudo ./scripts/validate-windows-iso.sh` |
| **VM作成: TPM設定失敗** | VirtualBox 6.x | VirtualBox 7.0以降へアップグレード |
| **Sysprep失敗: AppXエラー** | ストアアプリ残存 | AppX削除スクリプト再実行 |
| **FirstLogonCommands未実行** | スクリプトパス不正 | `C:\AutoSetup\setup.ps1` 存在確認 |
| **Clonezilla: ブート失敗** | UEFI設定不正 | `bootrec /fixboot && bootrec /rebuildbcd` |

---

## 次のステップ

### 1. DRBL管理Webアプリケーション連携

`setup.ps1` スクリプトをDRBL APIと連携させる：

```powershell
# DRBL APIからPC名・ODJファイル取得
$Serial = (Get-CimInstance Win32_BIOS).SerialNumber
$Response = Invoke-RestMethod -Uri "http://drbl-server/api/pcinfo?serial=$Serial"
Rename-Computer -NewName $Response.pcname -Force
djoin /requestODJ /loadfile $Response.odj_path /windowspath C:\Windows /localos
```

### 2. PXEブート環境構築

**参照**: DRBLサーバ構築ドキュメント

### 3. 本番環境展開

- マスターイメージをDRBLサーバへ配置
- 100台規模の同時展開テスト
- セットアップログ監視ダッシュボード構築

---

## 参考リンク

- [Microsoft Windows 11 ダウンロード](https://www.microsoft.com/ja-jp/software-download/windows11)
- [VirtualBox公式ドキュメント](https://www.virtualbox.org/manual/)
- [Clonezilla公式サイト](https://clonezilla.org/)
- [DRBL公式ドキュメント](https://drbl.org/)
- [Microsoft: Sysprep公式リファレンス](https://docs.microsoft.com/ja-jp/windows-hardware/manufacture/desktop/sysprep--generalize--a-windows-installation)

---

## ディレクトリ構造

```
/mnt/Linux-ExHDD/PCSetUpAutomation-CloneZillaServer-Project/
├── media/
│   └── Windows11.iso                        # 5.7GB ISOファイル
├── scripts/
│   ├── validate-windows-iso.sh              # ISO検証スクリプト（12KB）
│   └── setup-test-vm.sh                     # VirtualBox VM自動作成（12KB）
├── configs/
│   └── sysprep/
│       ├── unattend.xml                     # Sysprep応答ファイル（12KB）
│       └── README.md                        # unattend.xml使用ガイド（7.7KB）
├── docs/
│   ├── 運用管理/
│   │   └── マスターイメージ作成ガイド.md   # マスターPC構築手順（15KB）
│   ├── テスト/
│   │   └── ISO検証手順書.md                 # ISO検証詳細手順（15KB）
│   └── Windows11ISO検証環境構築サマリー.md   # 本ドキュメント
└── powershell-scripts/
    └── (既存の自動セットアップスクリプト)
```

---

## 改訂履歴

| バージョン | 日付 | 変更内容 |
|------------|------|----------|
| 1.0 | 2025-11-17 | 初版作成（ISO検証環境構築完了） |

---

**作成者**: API開発チーム (devapi agent)
**プロジェクト**: 会社キッティング自動化フレームワーク
**ステータス**: 検証環境構築完了、本番環境展開準備中
