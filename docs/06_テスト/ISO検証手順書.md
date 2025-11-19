# ISO検証手順書

**バージョン**: 1.0
**最終更新**: 2025-11-17
**対象**: Windows11.iso (5.7GB)

---

## 目次

1. [概要](#概要)
2. [自動検証スクリプト実行](#自動検証スクリプト実行)
3. [手動検証手順](#手動検証手順)
4. [チェックサム確認手順](#チェックサム確認手順)
5. [VMwareでのテストインストール](#vmwareでのテストインストール)
6. [VirtualBoxでのテストインストール](#virtualboxでのテストインストール)
7. [検証チェックリスト](#検証チェックリスト)
8. [トラブルシューティング](#トラブルシューティング)

---

## 概要

### 目的

Windows11.isoファイルの整合性を検証し、マスターイメージ作成前に以下を確認：

- ISOファイルの破損・改ざんがないこと
- Windows 11の正規インストールメディアであること
- 仮想環境でのインストールテストが成功すること

### 検証環境

| 項目 | 要件 |
|------|------|
| OS | Ubuntu 22.04 LTS以降 |
| RAM | 8GB以上 |
| ディスク空き容量 | 50GB以上 |
| 仮想化 | VirtualBox または VMware Workstation |
| ネットワーク | インターネット接続（検証ツール導入用） |

---

## 自動検証スクリプト実行

### 1. スクリプト実行

```bash
# プロジェクトルートディレクトリへ移動
cd /mnt/Linux-ExHDD/PCSetUpAutomation-CloneZillaServer-Project

# 実行権限確認
chmod +x scripts/validate-windows-iso.sh

# 検証実行（デフォルトパス）
./scripts/validate-windows-iso.sh

# または明示的にパス指定
./scripts/validate-windows-iso.sh /mnt/Linux-ExHDD/PCSetUpAutomation-CloneZillaServer-Project/media/Windows11.iso
```

### 2. 検証結果確認

**成功例**:
```
================================================================================
[INFO] Windows 11 ISO検証を開始します
[INFO] ISOファイル: /mnt/Linux-ExHDD/PCSetUpAutomation-CloneZillaServer-Project/media/Windows11.iso
================================================================================

[INFO] [1/7] ISOファイルの存在確認
[SUCCESS] ISOファイルが存在します

[INFO] [2/7] ファイルサイズチェック
[INFO] ファイルサイズ: 5.70GB
[SUCCESS] ファイルサイズは正常範囲内です (5.70GB)

[INFO] [3/7] ファイルタイプ確認
[INFO] ファイルタイプ: ISO 9660 CD-ROM filesystem data 'CCCOMA_X64FRE_EN-US_DV9'
[SUCCESS] 正しいISO 9660フォーマットです

[INFO] [4/7] SHA256チェックサム計算中... (数分かかる場合があります)
[SUCCESS] SHA256: a1b2c3d4e5f6...
[PASS] SHA256チェックサム算出完了

[INFO] [5/7] ISOマウントテスト
[SUCCESS] ISOマウント成功: /tmp/win11_iso_mount_12345
[SUCCESS] boot.wimファイルが存在します

[INFO] [7/7] 必須ファイル・フォルダ確認
[SUCCESS] ✓ sources
[SUCCESS] ✓ boot
[SUCCESS] ✓ efi
[SUCCESS] ✓ bootmgr
[SUCCESS] ✓ setup.exe

================================================================================
[INFO] 検証結果サマリー
================================================================================
[PASS] ISOファイル存在確認
[PASS] ファイルサイズ: 5.70GB
[PASS] ファイルタイプ: ISO 9660
[INFO] SHA256チェックサム算出完了
[PASS] ISOマウント
[PASS] 必須項目: sources

統計: PASS=15, FAIL=0, WARN=0, INFO=2
[SUCCESS] 検証完了: ISOファイルは正常です
[INFO] 詳細レポート: ./iso_validation_report_20251117_103045.txt
```

### 3. レポート確認

```bash
# 最新のレポートファイルを表示
cat iso_validation_report_*.txt | less
```

---

## 手動検証手順

### 1. 必須ツールインストール

```bash
# wimlibツール（WIMイメージ解析用）
sudo apt update
sudo apt install wimtools -y

# ISOマウント用ツール
sudo apt install fuseiso -y
```

### 2. ISOファイル存在確認

```bash
# ファイル存在とサイズ確認
ls -lh /mnt/Linux-ExHDD/PCSetUpAutomation-CloneZillaServer-Project/media/Windows11.iso

# 期待値: 5.7GB程度
```

### 3. ファイルタイプ確認

```bash
file /mnt/Linux-ExHDD/PCSetUpAutomation-CloneZillaServer-Project/media/Windows11.iso

# 期待値: "ISO 9660 CD-ROM filesystem data"
```

### 4. ISOマウントテスト

```bash
# マウントポイント作成
sudo mkdir -p /mnt/win11iso

# ISOマウント
sudo mount -o loop,ro /mnt/Linux-ExHDD/PCSetUpAutomation-CloneZillaServer-Project/media/Windows11.iso /mnt/win11iso

# 内容確認
ls -lh /mnt/win11iso

# 必須ファイル確認
ls /mnt/win11iso/sources/install.wim
ls /mnt/win11iso/sources/boot.wim
ls /mnt/win11iso/setup.exe

# アンマウント
sudo umount /mnt/win11iso
```

### 5. WIMイメージ情報抽出

```bash
# install.wimの情報取得
sudo mount -o loop,ro /mnt/Linux-ExHDD/PCSetUpAutomation-CloneZillaServer-Project/media/Windows11.iso /mnt/win11iso

wiminfo /mnt/win11iso/sources/install.wim

# エディション一覧表示
wiminfo /mnt/win11iso/sources/install.wim | grep "Display Name"

# 期待値:
# Display Name: Windows 11 Home
# Display Name: Windows 11 Pro
# Display Name: Windows 11 Enterprise

sudo umount /mnt/win11iso
```

---

## チェックサム確認手順

### 1. SHA256ハッシュ計算

```bash
# SHA256計算（数分かかる）
sha256sum /mnt/Linux-ExHDD/PCSetUpAutomation-CloneZillaServer-Project/media/Windows11.iso > Windows11.iso.sha256

# ハッシュ値表示
cat Windows11.iso.sha256
```

### 2. Microsoft公式ハッシュと比較

**Microsoft公式サイトからのダウンロード時**:

1. ダウンロードページに記載されているSHA256ハッシュをコピー
2. 比較実行:

```bash
# 期待値ファイル作成
echo "公式SHA256ハッシュ値  Windows11.iso" > expected.sha256

# 比較
sha256sum -c expected.sha256

# 成功時: "Windows11.iso: OK"
# 失敗時: "Windows11.iso: FAILED"
```

### 3. MD5ハッシュ計算（オプション）

```bash
# MD5計算（SHA256より高速だが非推奨）
md5sum /mnt/Linux-ExHDD/PCSetUpAutomation-CloneZillaServer-Project/media/Windows11.iso > Windows11.iso.md5
```

---

## VMwareでのテストインストール

### 前提条件

- VMware Workstation Pro/Player 17以降
- ホストマシン: 16GB RAM以上、50GB空き容量

### 1. 仮想マシン作成

**VMware設定**:
```
名前: Win11-Test
ゲストOS: Microsoft Windows → Windows 11 x64
メモリ: 8GB（8192 MB）
プロセッサ: 2コア
ディスク: 64GB（動的割り当て）
ネットワーク: NAT
```

### 2. TPM/セキュアブート設定

**VMXファイル編集**（VM停止状態で実行）:

```bash
# VMXファイルの場所を確認
find ~/vmware -name "Win11-Test.vmx"

# 以下を追加
echo 'firmware = "efi"' >> ~/vmware/Win11-Test/Win11-Test.vmx
echo 'managedVM.autoAddVTPM = "software"' >> ~/vmware/Win11-Test/Win11-Test.vmx
```

### 3. ISOアタッチ

VMware画面で:
1. **VM Settings** → **CD/DVD (SATA)**
2. **Use ISO image file** を選択
3. `/mnt/Linux-ExHDD/PCSetUpAutomation-CloneZillaServer-Project/media/Windows11.iso` を指定
4. **Connect at power on** にチェック

### 4. インストール実行

1. VM起動
2. Windows 11インストール開始
3. エディション選択: **Windows 11 Pro**
4. インストール完了まで待機（30-40分）

### 5. 検証ポイント

**成功基準**:
- [ ] インストーラーが正常起動
- [ ] ディスクパーティション作成成功
- [ ] ファイルコピー完了（エラーなし）
- [ ] 初回起動成功（OOBE画面表示）
- [ ] デスクトップ表示まで到達

---

## VirtualBoxでのテストインストール

### 前提条件

- VirtualBox 7.0以降
- ホストマシン: 16GB RAM以上、50GB空き容量

### 1. 仮想マシン作成（コマンドライン）

```bash
# VirtualBox仮想マシン作成
VBoxManage createvm --name "Win11-Test" --ostype Windows11_64 --register

# メモリ設定（8GB）
VBoxManage modifyvm "Win11-Test" --memory 8192

# プロセッサ設定（2コア）
VBoxManage modifyvm "Win11-Test" --cpus 2

# UEFI/セキュアブート設定
VBoxManage modifyvm "Win11-Test" --firmware efi
VBoxManage modifyvm "Win11-Test" --secure-boot on

# TPM設定
VBoxManage modifyvm "Win11-Test" --tpm-type 2.0

# ディスク作成（64GB）
VBoxManage createhd --filename ~/VirtualBox\ VMs/Win11-Test/Win11-Test.vdi --size 65536

# ストレージコントローラー追加
VBoxManage storagectl "Win11-Test" --name "SATA Controller" --add sata --controller IntelAhci

# ディスクアタッチ
VBoxManage storageattach "Win11-Test" --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium ~/VirtualBox\ VMs/Win11-Test/Win11-Test.vdi

# ISOアタッチ
VBoxManage storageattach "Win11-Test" --storagectl "SATA Controller" --port 1 --device 0 --type dvddrive --medium /mnt/Linux-ExHDD/PCSetUpAutomation-CloneZillaServer-Project/media/Windows11.iso

# ネットワーク設定
VBoxManage modifyvm "Win11-Test" --nic1 nat
```

### 2. 仮想マシン起動

```bash
# ヘッドレス起動（バックグラウンド）
VBoxManage startvm "Win11-Test" --type headless

# GUI起動
VBoxManage startvm "Win11-Test" --type gui
```

### 3. 自動セットアップスクリプト（オプション）

```bash
#!/bin/bash
# scripts/setup-test-vm.sh

VM_NAME="Win11-Test-$(date +%Y%m%d%H%M%S)"
ISO_PATH="/mnt/Linux-ExHDD/PCSetUpAutomation-CloneZillaServer-Project/media/Windows11.iso"
VM_DIR="$HOME/VirtualBox VMs/$VM_NAME"

# 仮想マシン作成
VBoxManage createvm --name "$VM_NAME" --ostype Windows11_64 --register
VBoxManage modifyvm "$VM_NAME" --memory 8192 --cpus 2 --firmware efi --secure-boot on --tpm-type 2.0

# ディスク作成
VBoxManage createhd --filename "$VM_DIR/$VM_NAME.vdi" --size 65536

# ストレージ設定
VBoxManage storagectl "$VM_NAME" --name "SATA" --add sata --controller IntelAhci
VBoxManage storageattach "$VM_NAME" --storagectl "SATA" --port 0 --device 0 --type hdd --medium "$VM_DIR/$VM_NAME.vdi"
VBoxManage storageattach "$VM_NAME" --storagectl "SATA" --port 1 --device 0 --type dvddrive --medium "$ISO_PATH"

# ネットワーク設定
VBoxManage modifyvm "$VM_NAME" --nic1 nat

# VM起動
VBoxManage startvm "$VM_NAME" --type gui

echo "仮想マシン '$VM_NAME' を作成・起動しました"
```

### 4. スクリプト実行権限付与

```bash
chmod +x /mnt/Linux-ExHDD/PCSetUpAutomation-CloneZillaServer-Project/scripts/setup-test-vm.sh
```

---

## 検証チェックリスト

### ISO整合性チェック

- [ ] **ファイルサイズ**: 5GB以上
- [ ] **ファイルタイプ**: ISO 9660フォーマット
- [ ] **SHA256ハッシュ**: 計算完了（公式ハッシュと一致する場合は記録）
- [ ] **ISOマウント**: 成功
- [ ] **install.wim存在**: 確認済み
- [ ] **boot.wim存在**: 確認済み
- [ ] **setup.exe存在**: 確認済み

### VMwareインストールテスト

- [ ] **VM作成**: 成功
- [ ] **TPM設定**: 有効化
- [ ] **セキュアブート**: 有効化
- [ ] **ISOアタッチ**: 成功
- [ ] **インストーラー起動**: 成功
- [ ] **パーティション作成**: 成功
- [ ] **ファイルコピー**: エラーなし
- [ ] **初回起動**: OOBE画面表示
- [ ] **デスクトップ到達**: 成功

### VirtualBoxインストールテスト

- [ ] **VM作成**: 成功
- [ ] **TPM 2.0設定**: 有効化
- [ ] **UEFI/セキュアブート**: 有効化
- [ ] **ISOアタッチ**: 成功
- [ ] **インストーラー起動**: 成功
- [ ] **パーティション作成**: 成功
- [ ] **ファイルコピー**: エラーなし
- [ ] **初回起動**: OOBE画面表示
- [ ] **デスクトップ到達**: 成功

### Windows 11バージョン確認

- [ ] **エディション**: Home/Pro/Enterprise含まれる
- [ ] **ビルド番号**: 記録（例: 22621）
- [ ] **アーキテクチャ**: x64
- [ ] **言語**: 日本語（ja-JP）または英語（en-US）

---

## トラブルシューティング

### ISO検証スクリプトエラー

#### 症状: mount: /tmp/win11_iso_mount_XXX: mount failed: Operation not permitted

**原因**: sudo権限不足

**解決策**:
```bash
sudo ./scripts/validate-windows-iso.sh
```

#### 症状: wiminfo: command not found

**原因**: wimtoolsパッケージ未インストール

**解決策**:
```bash
sudo apt install wimtools -y
```

### VMwareインストールエラー

#### 症状: This PC can't run Windows 11

**原因**: TPM/セキュアブート未設定

**解決策**:
1. VMを停止
2. VMXファイルに以下を追加:
   ```
   firmware = "efi"
   managedVM.autoAddVTPM = "software"
   ```
3. VM再起動

#### 症状: インストール中にエラーコード 0x80300001

**原因**: ディスクパーティション形式不一致

**解決策**:
- インストーラーで既存パーティションを削除
- 新規パーティションを作成（GPT形式）

### VirtualBoxインストールエラー

#### 症状: FATAL: No bootable medium found

**原因**: ISOが正しくアタッチされていない

**解決策**:
```bash
# ISOアタッチ確認
VBoxManage showvminfo "Win11-Test" | grep "SATA"

# 再アタッチ
VBoxManage storageattach "Win11-Test" --storagectl "SATA Controller" --port 1 --device 0 --type dvddrive --medium /mnt/Linux-ExHDD/PCSetUpAutomation-CloneZillaServer-Project/media/Windows11.iso
```

#### 症状: VirtualBox UEFI起動失敗

**原因**: セキュアブート証明書未登録

**解決策**:
```bash
# セキュアブートを一時的に無効化
VBoxManage modifyvm "Win11-Test" --secure-boot off

# インストール後に再有効化
VBoxManage modifyvm "Win11-Test" --secure-boot on
```

---

## 付録

### 推奨検証頻度

| タイミング | 検証内容 |
|------------|----------|
| **ISO初回配置時** | 完全検証（チェックサム + VMテスト） |
| **マスターイメージ作成前** | 自動スクリプト検証 |
| **月次** | チェックサム再確認 |
| **Microsoft更新後** | 新ISOの完全検証 |

### 参考リンク

- [Microsoft Windows 11 ダウンロード](https://www.microsoft.com/ja-jp/software-download/windows11)
- [VirtualBox公式ドキュメント](https://www.virtualbox.org/manual/)
- [VMware Workstation ドキュメント](https://docs.vmware.com/jp/VMware-Workstation-Pro/)

### 改訂履歴

| バージョン | 日付 | 変更内容 |
|------------|------|----------|
| 1.0 | 2025-11-17 | 初版作成 |

---

**作成者**: API開発チーム
**承認者**: IT部門長
