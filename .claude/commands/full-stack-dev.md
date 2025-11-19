---
description: フルスタック開発（全コンポーネント同時開発）
---

すべてのコンポーネントを並列で開発します。

以下のエージェントを**並列で**起動してください：

## バックエンド層
1. **database-architect**: データベーススキーマ設計（pc_master, setup_logs）
2. **flask-backend-dev**: Flask管理GUI実装
3. **api-developer**: REST API実装

## クライアント層
4. **powershell-scripter**: Windows自動セットアップスクリプト
5. **windows-automation**: Sysprep、unattend.xml設定

## インフラ層
6. **linux-sysadmin**: DRBL/Clonezillaサーバ設定

## 品質保証層
7. **test-engineer**: ユニットテスト作成
8. **integration-tester**: E2Eテストシナリオ作成

## DevOps層
9. **devops-engineer**: CI/CD設定、Docker化

## ドキュメント層
10. **documentation-writer**: 全体ドキュメント作成

各エージェントは独立したモジュールを担当し、API契約に基づいて並列開発します。
定期的に統合テストを実行し、整合性を確認してください。

完了後、システム全体の統合テストを実施してください。
