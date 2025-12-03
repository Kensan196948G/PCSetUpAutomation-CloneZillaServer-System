---
description: Git変更をコミット・プッシュし、PR（またはRelease）を作成
tags: [git, github, workflow]
---

# Git Commit → Push → PR/Release ワークフロー

このコマンドは、Git変更の完全なワークフロー（コミット → プッシュ → PR/Release作成）を自動化します。

## 実行内容

1. **変更状況の確認**
   - `git status` で変更ファイルを確認
   - `git diff --stat` で変更統計を取得
   - `git log --oneline -5` で最近のコミット履歴を確認

2. **変更の分析**
   - 変更内容を分析
   - 適切なコミットメッセージを生成

3. **ステージング**
   - `git add -A` で全変更をステージング
   - ステージング結果を確認

4. **コミット作成**
   - 変更内容に基づいた詳細なコミットメッセージを作成
   - Conventional Commits形式（feat、fix、docs等）
   - Claude Code署名付き

5. **プッシュ**
   - `git push origin <branch>` でリモートへプッシュ

6. **PR/Release作成**
   - **featureブランチの場合**: `gh pr create` でPR作成
   - **mainブランチの場合**: ユーザーに選択肢を提示
     - GitHub Release作成（タグ + リリースノート）
     - developブランチを作成してPRワークフロー確立
     - このまま完了（PR/Releaseなし）

## 使用例

```bash
# 変更後、このコマンドを実行
/commit-push-pr
```

## 生成されるコミットメッセージ形式

```
<type>: <subject>

## <詳細セクション>

### <変更カテゴリ1>
- 変更内容1
- 変更内容2

### <変更カテゴリ2>
- 変更内容1

## 📊 統計

- 変更ファイル: X個
- 追加行: X行
- 削除行: X行

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

## Conventional Commits タイプ

- `feat`: 新機能
- `fix`: バグ修正
- `docs`: ドキュメントのみの変更
- `refactor`: リファクタリング
- `test`: テスト追加・修正
- `chore`: ビルドプロセスやツールの変更
- `perf`: パフォーマンス改善

## PR作成時のテンプレート

```markdown
## Summary
<変更内容の要約>

## Changes
- 変更1
- 変更2
- 変更3

## Test Plan
- [ ] ユニットテスト実行
- [ ] 統合テスト実行
- [ ] 手動テスト実施

## Related Issues
Closes #<issue_number>

🤖 Generated with [Claude Code](https://claude.com/claude-code)
```

## Release作成時のテンプレート

```markdown
## 🎉 Release <version>

**リリース日**: <date>
**リリースタイプ**: <type>

---

## 主な変更内容

### 新機能
- 機能1
- 機能2

### バグ修正
- 修正1
- 修正2

### ドキュメント更新
- 更新1
- 更新2

---

## アップグレード手順

1. リポジトリを更新
2. 依存関係を更新
3. 設定ファイルを確認

---

## 変更統計

- 変更ファイル: X個
- 追加行: X行
- 削除行: X行

🤖 Generated with [Claude Code](https://claude.com/claude-code)
```

## 注意事項

- **mainブランチへの直接プッシュ**: 慎重に実行（本番環境への影響を考慮）
- **機密情報の確認**: コミット前に.env、.db等が除外されていることを確認
- **テスト実行**: 重要な変更の場合、コミット前にテストを実行
- **ブランチ保護**: 本番環境では、mainブランチへの直接プッシュを禁止し、PR経由のみを許可することを推奨

## 関連コマンド

- `/test-all` - 全テスト実行
- `/deploy` - デプロイメント実行
- `/mcp-deploy-check` - デプロイ前チェック
