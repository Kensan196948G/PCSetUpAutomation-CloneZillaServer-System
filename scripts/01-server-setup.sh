#!/bin/bash
# Clonezilla Serverの初期セットアップスクリプト
# 使用方法: sudo ./01-server-setup.sh

set -e

echo "=========================================="
echo "Clonezilla Server セットアップスクリプト"
echo "=========================================="
echo ""

# rootチェック
if [ "$EUID" -ne 0 ]; then 
    echo "エラー: このスクリプトはroot権限で実行してください"
    echo "使用方法: sudo ./01-server-setup.sh"
    exit 1
fi

# Ubuntu バージョンチェック
if [ -f /etc/os-release ]; then
    . /etc/os-release
    if [ "$ID" != "ubuntu" ]; then
        echo "警告: このスクリプトはUbuntu用に設計されています"
        echo "現在のOS: $PRETTY_NAME"
        read -p "続行しますか？ (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
fi

echo "ステップ 1/8: システムの更新..."
apt update
apt upgrade -y

echo ""
echo "ステップ 2/8: 基本パッケージのインストール..."
apt install -y \
    curl \
    wget \
    vim \
    net-tools \
    iftop \
    htop \
    nfs-kernel-server \
    nfs-common

echo ""
echo "ステップ 3/8: DRBLリポジトリの追加..."
# DRBLのGPGキーを追加
wget -q https://drbl.org/GPG-KEY-DRBL -O- | apt-key add -

# DRBLリポジトリを追加
if [ ! -f /etc/apt/sources.list.d/drbl.list ]; then
    echo "deb http://free.nchc.org.tw/drbl-core drbl stable" > /etc/apt/sources.list.d/drbl.list
    echo "DRBLリポジトリを追加しました"
fi

apt update

echo ""
echo "ステップ 4/8: DRBL/Clonezillaのインストール..."
apt install -y drbl clonezilla

echo ""
echo "ステップ 5/8: イメージディレクトリの作成..."
mkdir -p /home/partimag
chmod 755 /home/partimag

echo ""
echo "ステップ 6/8: NFS設定..."
# NFSエクスポート設定
if ! grep -q "/home/partimag" /etc/exports; then
    echo "/home/partimag *(ro,async,no_wdelay,no_root_squash,insecure_locks,insecure)" >> /etc/exports
    echo "NFSエクスポート設定を追加しました"
fi

# NFSサービスを有効化・起動
systemctl enable nfs-kernel-server
systemctl restart nfs-kernel-server
exportfs -a

echo ""
echo "ステップ 7/8: ファイアウォール設定..."
# UFWがインストールされている場合のみ設定
if command -v ufw &> /dev/null; then
    ufw allow 22/tcp   # SSH
    ufw allow 67/udp   # DHCP
    ufw allow 69/udp   # TFTP
    ufw allow 111/tcp  # RPC
    ufw allow 111/udp  # RPC
    ufw allow 2049/tcp # NFS
    ufw allow 2049/udp # NFS
    
    # UFWが有効でない場合は有効化を提案
    if ! ufw status | grep -q "Status: active"; then
        echo "ファイアウォール設定を追加しました"
        echo "注意: UFWを有効化するには 'sudo ufw enable' を実行してください"
    fi
else
    echo "注意: UFWがインストールされていません。必要に応じてファイアウォール設定を行ってください"
fi

echo ""
echo "ステップ 8/8: ディレクトリ構造の作成..."
mkdir -p /home/partimag/scripts
mkdir -p /home/partimag/logs
mkdir -p /var/log/clonezilla

echo ""
echo "=========================================="
echo "セットアップ完了！"
echo "=========================================="
echo ""
echo "次のステップ:"
echo "1. ネットワーク設定を確認してください:"
echo "   - Netplan設定: /etc/netplan/00-installer-config.yaml"
echo "   - 静的IP: 192.168.100.1 を推奨"
echo ""
echo "2. DRBL初期設定を実行してください:"
echo "   sudo /usr/sbin/drblsrv -i"
echo ""
echo "3. DRBLクライアント設定を実行してください:"
echo "   sudo /usr/sbin/drblpush -i"
echo ""
echo "4. サービスの状態を確認してください:"
echo "   systemctl status nfs-kernel-server"
echo "   systemctl status dnsmasq"
echo ""
echo "詳細は README.md を参照してください。"
echo ""
