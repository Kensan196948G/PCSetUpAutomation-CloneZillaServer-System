# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.1.0] - 2025-11-19

### 🔧 Fixed
- **Docker干渉問題の解決**
  - Dockerサービス（docker0インターフェース）がDRBL環境と競合する問題を修正
  - atftpdとtftpd-hpaのポート競合問題を解決
  - TFTPサーバが正常に起動するように修正

### ✨ Added
- **新規スクリプト**
  - `scripts/fix_drbl_docker_issue.sh` - Docker干渉問題の自動修正スクリプト
  - `configs/drblpush_auto_config.conf` - drblpush自動設定ファイル

- **新規ドキュメント**
  - `docs/04_インフラ/DRBL_FIX_DOCKER_GUIDE.md` - Docker問題の詳細ガイド
  - `docs/DOCKER_ISSUE_UPDATE_REPORT.md` - 今回の更新レポート
  - `CHANGELOG.md` - 本ファイル

- **Serenaメモリ**
  - `.serena/memories/drbl_troubleshooting.md` - DRBL トラブルシューティング情報

### 📝 Changed
- **プロジェクトルート整理**
  - 24ファイル → 5ファイルに整理（81%削減）
  - スクリプトを `scripts/` に集約（4ファイル移動）
  - レポート・ガイドを `docs/` 配下の適切なカテゴリに移動（14ファイル移動）
  - 設定ファイルを `configs/` に集約（1ファイル移動）
  - ログファイルを `logs/` に移動（1ファイル移動）

- **ドキュメント更新**（7ファイル）
  - `README.md` - v1.1.0、Docker前提条件追加、トラブルシューティングセクション追加
  - `START_HERE.md` - Docker無効化の前提条件追加、前提条件チェックリスト追加
  - `CLAUDE.md` - DRBL構築時の最重要注意事項としてDocker干渉問題を追記
  - `docs/04_インフラ/DRBL_Clonezillaサーバ構築手順.md` - v1.1、Docker干渉問題追加
  - `docs/04_インフラ/PXEブート環境構築手順.md` - v1.1、Docker干渉問題追加
  - `docs/04_インフラ/自宅環境PXEブート構築ガイド.md` - v1.1、Docker干渉問題追加
  - `docs/08_トラブルシューティング/トラブルシューティング集.md` - v1.1、PXE-000追加

- **PXEブート環境の完成**
  - isc-dhcp-server: active (running)
  - tftpd-hpa: active (running)
  - nfs-server: active (exited)
  - Clonezilla Live完全配置（vmlinuz 16MB、initrd 74MB、filesystem.squashfs 443MB）

### 🗂️ Moved
**scripts/** へ移動（4ファイル）:
- CHECK_PXE_READINESS.sh
- fix_drbl_docker_issue.sh
- fix_nfs_complete.sh
- unified_setup.sh

**docs/04_インフラ/** へ移動（5ファイル）:
- DRBL_QUICK_SETUP.md
- DRBL_FIX_DOCKER_GUIDE.md
- MANUAL_FIX_NFS.md
- NFS_FIX_SUMMARY.md
- QUICK_FIX_NFS.txt

**docs/00_プロジェクト概要/** へ移動（4ファイル）:
- COMPREHENSIVE_READINESS_REPORT.md
- DUAL_ENVIRONMENT_SETUP_REPORT.md
- FOLDER_STRUCTURE_REPORT.md
- PROJECT_RESTRUCTURE_REPORT.md

**docs/07_デプロイ/** へ移動（1ファイル）:
- FINAL_SETUP_GUIDE.md

**docs/11_参考資料/** へ移動（2ファイル）:
- ANSIBLE_INTRODUCTION_PLAN.md
- AUTOMATED_REMEDIATION_STRATEGY.md

**docs/08_トラブルシューティング/** へ移動（1ファイル）:
- NEXT_STEPS.md

**configs/** へ移動（1ファイル）:
- pxelinux.0

**logs/** へ移動（1ファイル）:
- nohup.out

### 🔐 Security
- なし（今回のリリースではセキュリティ関連の変更なし）

### ⚠️ Deprecated
- なし

### 🗑️ Removed
- なし（すべてのファイルは削除せず移動で対応）

---

## [1.0.0] - 2025-11-17

### ✨ Initial Release
- Flask管理Webアプリケーション
- REST API（/api/pcinfo、/api/log）
- PowerShell自動セットアップスクリプト
- SQLiteデータベース（pc_master、setup_logs）
- DRBL/Clonezilla環境構築ドキュメント
- テストスイート（ユニット、統合、E2E、パフォーマンス）
- 開発・本番環境分離
- Claude Code統合（24コマンド、10エージェント、7 MCP）
- 包括的ドキュメント（42ファイル、14カテゴリ）

---

## 更新者情報

- **v1.1.0**: Claude Code + DevOps Engineer Agent + Documentation Writer Agent
- **v1.0.0**: 初期リリースチーム

---

## リンク

- [プロジェクトREADME](./README.md)
- [スタートガイド](./START_HERE.md)
- [トラブルシューティング](./docs/08_トラブルシューティング/トラブルシューティング集.md)
- [Docker問題ガイド](./docs/04_インフラ/DRBL_FIX_DOCKER_GUIDE.md)
