# DRBL/Clonezillaサーバー設定

このディレクトリには、DRBL（Diskless Remote Boot in Linux）およびClonezilla Server Editionの設定ファイルが含まれています。

## 📋 概要

DRBLサーバーは以下の機能を提供します：
- PXEブート環境
- Clonezillaによるマスターイメージ展開
- 10〜20台の同時展開（マルチキャスト）

## 🖥️ システム要件

### ハードウェア
- CPU: 4コア以上
- メモリ: 8GB以上
- ストレージ: 500GB以上（イメージ保存用）
- ネットワーク: Gigabit Ethernet x2（管理用、PXE用）

### ソフトウェア
- OS: Ubuntu 22.04 LTS
- DRBL/Clonezilla Server Edition
- Python 3.10以上（管理GUI用）

## 📁 ディレクトリ構造

```
drbl-server/
├── README.md              # このファイル
├── install.sh            # DRBLインストールスクリプト
├── dhcpd.conf            # DHCP設定
├── pxelinux.cfg/         # PXEブート設定
│   └── default          # デフォルトPXEメニュー
└── scripts/              # 補助スクリプト
    ├── backup-image.sh  # イメージバックアップ
    └── cleanup.sh       # クリーンアップ
```

## 🚀 セットアップ手順

### 1. DRBLのインストール
```bash
cd drbl-server
sudo ./install.sh
```

### 2. DRBL設定
```bash
sudo /opt/drbl/sbin/drblsrv -i
sudo /opt/drbl/sbin/drblpush -i
```

### 3. Clonezillaイメージの配置
```bash
sudo cp -r /path/to/master/image /home/partimag/MASTER_2025_v1
```

### 4. マルチキャスト展開の開始
```bash
sudo /opt/drbl/sbin/dcs
```

## 🔧 主な設定ファイル

### dhcpd.conf
DHCPサーバーの設定。PXEブートに必要なオプションを含む。

### pxelinux.cfg/default
PXEブートメニューの設定。Clonezillaの起動オプションを指定。

## 📊 運用

### イメージの更新
1. マスターPCでSysprep実行
2. ClonezillaでイメージをDRBLサーバーに保存
3. イメージ名をバージョン管理（MASTER_YYYY_vX）

### 展開手順
1. DRBLサーバーでClonezilla Server Edition起動
2. 展開するイメージを選択
3. マルチキャストモードで展開開始
4. クライアントPCの電源ON（PXEブート）

## 🛡️ セキュリティ

- PXE用ネットワークは隔離VLAN推奨
- DHCPは特定MACアドレスのみ許可可能
- イメージファイルは権限管理

## 📝 トラブルシューティング

### PXEブートしない
- DHCPサーバーの動作確認
- ネットワークケーブルの確認
- BIOSのブート順序確認

### 展開が遅い
- ネットワーク帯域の確認
- 同時展開台数の調整
- マルチキャスト設定の確認

## 📚 参考資料

- [DRBL公式サイト](https://drbl.org/)
- [Clonezilla公式サイト](https://clonezilla.org/)
- Ubuntu Server Guide
