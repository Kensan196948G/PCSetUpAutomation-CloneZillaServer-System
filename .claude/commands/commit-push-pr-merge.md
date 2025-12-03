---
description: Git変更をコミット・プッシュし、PR作成後に自動マージまで実行
tags: [git, github, workflow, automation, merge]
---

# Git Commit → Push → PR → Merge 完全自動化ワークフロー

このコマンドは、Git変更の完全なワークフロー（コミット → プッシュ → PR作成 → 自動マージ）を完全自動化します。

`/commit-push-pr` コマンドの拡張版で、PR作成後に**自動的にマージまで実行**します。

---

## 🚀 実行内容

### ステップ1: 変更状況の確認と分析
- `git status` で変更ファイルを確認
- `git diff --stat` で変更統計を取得
- `git log --oneline -10` で最近のコミット履歴を確認
- 現在のブランチを確認（main、feature、develop等）

### ステップ2: ブランチ戦略の決定
- **現在mainブランチの場合**:
  - featureブランチを自動作成
  - ブランチ名: `feature/<変更内容に基づく名前>`
  - 例: `feature/fix-docker-issue`, `feature/add-api-endpoint`

- **現在featureブランチの場合**:
  - そのまま使用

### ステップ3: 変更のステージングとコミット
- `git add -A` で全変更をステージング
- 変更内容を分析して適切なコミットメッセージを生成
- Conventional Commits形式（feat、fix、docs等）
- Claude Code署名付きコミット作成

### ステップ4: リモートへプッシュ
- `git push origin <branch>` でリモートへプッシュ
- 新規ブランチの場合は `-u` フラグ付きでアップストリーム設定

### ステップ5: PR作成
- `gh pr create` でPull Request作成
- タイトル: コミットメッセージのサブジェクト
- 本文:
  - Summary（変更内容の要約）
  - Changes（変更リスト）
  - Test Plan（テスト計画）
  - Related Issues（関連Issue）

### ステップ6: 自動マージ ⭐ NEW!
- **マージ前チェック**:
  - [ ] CI/CDパイプライン成功確認（GitHub Actions）
  - [ ] コンフリクトなし確認
  - [ ] レビュー承認確認（設定されている場合）

- **マージ戦略の選択**:
  - ユーザーに選択肢を提示:
    - `squash`: Squash and merge（推奨、履歴を1コミットに圧縮）
    - `merge`: Create a merge commit（マージコミット作成）
    - `rebase`: Rebase and merge（リベースしてマージ）
    - `manual`: 手動マージ（自動マージをスキップ）

- **マージ実行**:
  - `gh pr merge <pr_number> --<strategy>` でマージ実行
  - マージ後、featureブランチを削除（オプション）

### ステップ7: 後処理
- mainブランチへ切り替え（マージ後）
- `git pull` で最新状態に更新
- マージ結果を表示

---

## 📋 使用例

### 基本的な使用（featureブランチから）

```bash
# 1. 変更を加える
vim flask-app/api/new_endpoint.py

# 2. このコマンドを実行
/commit-push-pr-merge

# 結果:
# ✅ コミット作成
# ✅ プッシュ
# ✅ PR作成
# ✅ 自動マージ（ユーザー選択後）
# ✅ mainブランチへ統合完了
```

### mainブランチから実行した場合

```bash
# 1. mainブランチで変更
vim README.md

# 2. このコマンドを実行
/commit-push-pr-merge

# 実行内容:
# ✅ featureブランチ自動作成（例: feature/update-readme）
# ✅ コミット作成
# ✅ プッシュ
# ✅ PR作成（feature → main）
# ✅ 自動マージ
# ✅ mainブランチへ戻る
```

---

## 🎯 マージ戦略の選択ガイド

### Squash and Merge（推奨）✨
```bash
gh pr merge <pr> --squash
```

**使用ケース**:
- ✅ 複数の小さなコミットを1つにまとめたい
- ✅ 履歴をクリーンに保ちたい
- ✅ featureブランチの詳細な履歴が不要

**利点**:
- mainブランチの履歴がシンプル
- 各featureが1コミットとして記録
- git logが読みやすい

**欠点**:
- 詳細なコミット履歴が失われる

---

### Create a Merge Commit
```bash
gh pr merge <pr> --merge
```

**使用ケース**:
- ✅ featureブランチの履歴を完全に保持したい
- ✅ 誰が何をいつ変更したか詳細に追跡したい
- ✅ 複雑な変更で履歴が重要

**利点**:
- 完全な履歴保持
- featureブランチの全コミットが保存される

**欠点**:
- mainブランチの履歴が複雑になる
- マージコミットが増える

---

### Rebase and Merge
```bash
gh pr merge <pr> --rebase
```

**使用ケース**:
- ✅ 線形な履歴を維持したい
- ✅ マージコミットを作りたくない
- ✅ featureブランチのコミットをそのままmainに追加したい

**利点**:
- 線形な履歴
- マージコミットなし

**欠点**:
- コミットハッシュが変更される
- 既にプッシュされたコミットの書き換え

---

## ⚙️ マージ前の自動チェック項目

コマンド実行時、以下を自動確認します：

### 1. CI/CDステータス確認
```bash
gh pr checks <pr_number>
```
- ✅ All checks passed → マージ可能
- ❌ Some checks failed → マージ警告、継続確認

### 2. コンフリクト確認
```bash
gh pr view <pr_number> --json mergeable
```
- ✅ No conflicts → マージ可能
- ❌ Conflicts detected → マージ不可、手動解決が必要

### 3. レビュー状態確認
```bash
gh pr view <pr_number> --json reviewDecision
```
- ✅ Approved → マージ可能
- ⏳ Review required → レビュー待ち警告
- ❌ Changes requested → 変更要求あり、マージ警告

### 4. ブランチ保護ルール確認
- mainブランチへのマージ時、保護ルールを確認
- 違反がある場合は警告表示

---

## 🔒 安全性の考慮

### 確認プロンプト
以下の場合、ユーザーに確認を求めます：

1. **mainブランチへの直接マージ**
   - 「本当にmainブランチへマージしますか？」

2. **CI/CDチェック失敗時**
   - 「チェックが失敗していますが、マージを続行しますか？」

3. **レビュー未承認時**
   - 「レビューが未承認ですが、マージを続行しますか？」

4. **コンフリクト検出時**
   - 「コンフリクトがあります。手動で解決してください。」
   - → マージを中止

### ロールバック機能
マージ後に問題が発見された場合のロールバック方法を表示：

```bash
# マージをリバート
git revert -m 1 <merge_commit_hash>
git push origin main
```

---

## 🎨 生成されるPR本文テンプレート

```markdown
## Summary
<変更内容の1-2文要約>

## 🔧 Changes
- 主要な変更1
- 主要な変更2
- 主要な変更3

## ✅ Test Plan
- [x] ユニットテスト実行済み
- [x] 統合テスト実行済み
- [ ] E2Eテスト実行（必要に応じて）
- [ ] 手動テスト実施

## 📊 Statistics
- 変更ファイル: X個
- 追加行: +X行
- 削除行: -X行

## 🔗 Related Issues
Closes #<issue_number>（該当する場合）

## 📝 Additional Notes
<追加の注意事項、既知の問題等>

---

🤖 Generated with [Claude Code](https://claude.com/claude-code)
```

---

## 🔄 ワークフロー全体図

```
┌─────────────────────────────────────────────────────────┐
│ ステップ1: 変更の確認と分析                              │
│ - git status, git diff, git log                        │
│ - ブランチ確認、変更内容の分析                          │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│ ステップ2: ブランチ戦略                                  │
│ - mainブランチ → featureブランチ自動作成                 │
│ - featureブランチ → そのまま使用                         │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│ ステップ3: コミット作成                                  │
│ - git add -A                                           │
│ - 適切なコミットメッセージ生成                          │
│ - git commit                                           │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│ ステップ4: プッシュ                                      │
│ - git push origin <branch>                             │
│ - 新規ブランチは -u フラグ付き                          │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│ ステップ5: PR作成                                        │
│ - gh pr create --title "..." --body "..."              │
│ - Summary、Changes、Test Plan含む                       │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│ ステップ6: マージ前チェック ⭐                           │
│ - CI/CDステータス確認                                   │
│ - コンフリクト確認                                      │
│ - レビュー状態確認                                      │
│ - ブランチ保護ルール確認                                │
└─────────────────────────────────────────────────────────┘
                          ↓
         ┌────────────────┴────────────────┐
         │                                  │
    ✅ All OK                          ❌ Issues Found
         │                                  │
         ↓                                  ↓
┌─────────────────────┐         ┌─────────────────────┐
│ ステップ7: マージ    │         │ 警告表示・確認要求   │
│ - ユーザーに戦略選択 │         │ - 続行するか確認     │
│ - squash/merge/rebase│         └─────────────────────┘
│ - gh pr merge        │
└─────────────────────┘
         ↓
┌─────────────────────────────────────────────────────────┐
│ ステップ8: 後処理                                        │
│ - mainブランチへ切り替え                                │
│ - git pull で最新状態に更新                             │
│ - featureブランチ削除（オプション）                     │
│ - マージ結果を表示                                      │
└─────────────────────────────────────────────────────────┘
```

---

## 🎯 コマンド実行例

### 例1: 新機能の追加（mainブランチから）

```bash
# 1. mainブランチで新機能を実装
git checkout main
vim flask-app/api/new_feature.py

# 2. コマンド実行
/commit-push-pr-merge

# 実行される処理:
# ✅ featureブランチ自動作成（feature/add-new-feature）
# ✅ 変更をコミット
# ✅ プッシュ
# ✅ PR作成（feature/add-new-feature → main）
# ✅ マージ戦略選択プロンプト表示
# ✅ 自動マージ実行
# ✅ mainブランチへ戻る
```

### 例2: バグ修正（featureブランチから）

```bash
# 1. featureブランチで作業
git checkout -b fix/api-bug
vim flask-app/api/pcinfo.py

# 2. コマンド実行
/commit-push-pr-merge

# 実行される処理:
# ✅ 変更をコミット
# ✅ プッシュ
# ✅ PR作成（fix/api-bug → main）
# ✅ CI/CDチェック確認
# ✅ 自動マージ実行（squash推奨）
# ✅ mainブランチへ戻る
# ✅ featureブランチ削除（オプション）
```

---

## 📊 生成されるコミットメッセージ

```
<type>: <subject>

## 📝 変更内容

### <カテゴリ1>
- 変更1
- 変更2

### <カテゴリ2>
- 変更3

## ✅ テスト

- [x] ユニットテスト実行
- [x] 統合テスト実行
- [ ] E2Eテスト（必要に応じて）

## 📊 統計

- 変更ファイル: X個
- 追加行: +X行
- 削除行: -X行

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

---

## 🎨 生成されるPR本文

```markdown
## Summary

<変更内容の1-3文要約>

---

## 🔧 Changes

- 主要な変更1（ファイルパス付き）
- 主要な変更2（ファイルパス付き）
- 主要な変更3（ファイルパス付き）

---

## ✅ Test Plan

- [x] ユニットテスト実行済み（`pytest tests/unit/`）
- [x] 統合テスト実行済み（`pytest tests/integration/`）
- [ ] E2Eテスト実行（必要に応じて）
- [ ] パフォーマンステスト（必要に応じて）
- [ ] 手動テスト実施

---

## 📊 Statistics

| メトリック | 値 |
|----------|-----|
| 変更ファイル | X個 |
| 追加行 | +X行 |
| 削除行 | -X行 |
| 影響範囲 | <モジュール名> |

---

## 🔗 Related Issues

Closes #<issue_number>（該当する場合）

---

## 📝 Additional Notes

<追加の注意事項>
- 破壊的変更の有無
- マイグレーション必要性
- 設定変更の必要性
- 既知の制限事項

---

## 🔍 Review Checklist

- [ ] コードレビュー完了
- [ ] セキュリティチェック
- [ ] パフォーマンス影響確認
- [ ] ドキュメント更新確認

---

🤖 Generated with [Claude Code](https://claude.com/claude-code)
```

---

## ⚙️ マージオプション詳細

### オプション1: Squash and Merge（推奨）

```bash
gh pr merge <pr_number> --squash --delete-branch
```

**特徴**:
- featureブランチの全コミットを1つに圧縮
- mainブランチの履歴がクリーン
- PRタイトルがコミットメッセージになる

**推奨ケース**:
- 小規模〜中規模の変更
- 履歴のシンプルさを重視
- featureブランチの詳細履歴が不要

---

### オプション2: Create a Merge Commit

```bash
gh pr merge <pr_number> --merge --delete-branch
```

**特徴**:
- マージコミットを作成
- featureブランチの全履歴を保持
- 「Merge pull request #X」コミットが作成される

**推奨ケース**:
- 大規模な変更
- 詳細な履歴追跡が重要
- 複数人での共同開発

---

### オプション3: Rebase and Merge

```bash
gh pr merge <pr_number> --rebase --delete-branch
```

**特徴**:
- featureブランチのコミットをmainに直接追加
- マージコミットなし
- 線形な履歴

**推奨ケース**:
- 単一機能の追加
- 線形履歴を維持したい
- コミットが既に整理されている

---

### オプション4: Manual（手動マージ）

```bash
# マージをスキップ
```

**推奨ケース**:
- レビュー待ち
- CI/CDチェック待ち
- 追加の変更が必要

---

## 🛡️ 安全機能

### 1. プリフライトチェック
```bash
# コミット前チェック
- [ ] .env、.db等の機密ファイルが含まれていないか
- [ ] テストが実行されているか（重要な変更の場合）
- [ ] コードフォーマットが適用されているか

# マージ前チェック
- [ ] CI/CDパイプライン成功
- [ ] コンフリクトなし
- [ ] レビュー承認（設定されている場合）
```

### 2. ロールバック情報の表示
マージ完了後、問題発生時のロールバック方法を表示：

```bash
# マージをリバート
git checkout main
git pull
git revert -m 1 <merge_commit_hash>
git push origin main

# または
gh pr reopen <pr_number>  # PRを再オープン
```

### 3. ブランチクリーンアップ
マージ後、featureブランチを削除するか確認：

```bash
# ローカルブランチ削除
git branch -d feature/xxx

# リモートブランチ削除（gh pr mergeで自動）
git push origin --delete feature/xxx
```

---

## 📝 Conventional Commits タイプ

自動検出されるコミットタイプ：

| タイプ | 説明 | 例 |
|-------|------|-----|
| `feat` | 新機能 | 新しいAPIエンドポイント追加 |
| `fix` | バグ修正 | Docker干渉問題の修正 |
| `docs` | ドキュメント変更 | READMEの更新 |
| `refactor` | リファクタリング | コード構造の改善 |
| `test` | テスト追加・修正 | E2Eテストの追加 |
| `chore` | ビルド・ツール変更 | 依存関係の更新 |
| `perf` | パフォーマンス改善 | DB クエリ最適化 |
| `style` | コードスタイル変更 | フォーマット修正 |
| `ci` | CI/CD変更 | GitHub Actions更新 |

---

## 🚨 エラーハンドリング

### CI/CDチェック失敗時
```
⚠️ Warning: CI/CD checks have failed

Failed checks:
- pytest (exit code 1)
- flake8 (2 errors found)

Options:
1. Fix the issues and re-run /commit-push-pr-merge
2. Continue anyway (not recommended)
3. Cancel

Your choice:
```

### コンフリクト検出時
```
❌ Error: Merge conflicts detected

This PR has conflicts with the base branch (main).
Please resolve conflicts manually:

1. git checkout main
2. git pull
3. git checkout <feature_branch>
4. git merge main
5. Resolve conflicts
6. git push
7. Re-run /commit-push-pr-merge

Merge aborted.
```

### レビュー未承認時
```
⚠️ Warning: PR review is pending

Review status: REVIEW_REQUIRED
Approvals: 0 / 1 required

Options:
1. Wait for review
2. Continue anyway (requires admin permissions)
3. Cancel

Your choice:
```

---

## 🔗 関連コマンド

- `/commit-push-pr` - PR作成まで（マージなし）
- `/test-all` - 全テスト実行
- `/mcp-deploy-check` - デプロイ前チェック
- `/deploy` - デプロイメント実行
- `/mcp-code-quality` - コード品質チェック

---

## 💡 使い分けガイド

### `/commit-push-pr` を使うべき場合
- レビューを待ちたい
- CI/CDチェック結果を確認してから手動でマージしたい
- PRを作成するだけで十分

### `/commit-push-pr-merge` を使うべき場合
- 小規模な変更で即座にマージしたい
- レビュー不要な変更（ドキュメント、タイポ修正等）
- 自分のfeatureブランチで完全にテスト済み
- CI/CDが自動的にチェックしてくれる環境

---

## ⚠️ 注意事項

### 本番環境での使用
- **ブランチ保護ルール設定を推奨**: mainブランチへの直接プッシュを禁止
- **レビュー必須化を推奨**: 重要な変更は必ずレビューを経由
- **CI/CD必須化を推奨**: すべてのチェックパス後のみマージ可能に設定

### 機密情報の確認
- コミット前に `.gitignore` で除外されていることを確認
- `.env`、`*.db`、`odj-files/*.txt` 等が含まれていないか自動チェック

### テスト実行
- 重要な変更の場合、`/test-all` を先に実行することを推奨
- CI/CDパイプラインが設定されている場合は自動実行

---

## 📖 詳細ドキュメント

- [Git Workflow Guide](../../docs/03_開発/Git運用ガイド.md)（作成予定）
- [GitHub Actions CI/CD](../../.github/workflows/ci.yml)
- [Branch Protection Rules](../../docs/03_開発/ブランチ保護ルール.md)（作成予定）

---

**コマンド作成日**: 2025-12-03
**バージョン**: 1.0.0
**依存コマンド**: `/commit-push-pr`
**総スラッシュコマンド数**: 26個
