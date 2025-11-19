---
description: MCP統合でコード品質を総合評価
---

**複数MCP統合**でコード品質を多角的に評価します。

## 実行内容

### 使用するMCPサーバ

1. **Serena** → コード構造・パターン分析
2. **Context7** → ベストプラクティス確認
3. **Sequential Thinking** → 品質改善戦略
4. **Memory** → 過去の品質改善履歴

## 評価項目

### 1. コーディング規約
- PEP 8 準拠（Python）
- PowerShell規約準拠
- 命名規則統一性

### 2. アーキテクチャパターン
- MVC/Blueprint 適切な使用
- 関心の分離（Separation of Concerns）
- DRY原則（Don't Repeat Yourself）

### 3. エラーハンドリング
- Try-Catch-Finally 適切な使用
- エラーメッセージの明確性
- ロギング実装

### 4. テスト品質
- ユニットテストカバレッジ
- テストケース網羅性
- モック適切な使用

### 5. セキュリティ
- 入力バリデーション
- SQLインジェクション対策
- XSS対策

### 6. パフォーマンス
- N+1問題の有無
- 不要なループ
- メモリリーク可能性

## 出力レポート

### スコアリング（各項目100点満点）
- コーディング規約: XX点
- アーキテクチャ: XX点
- エラーハンドリング: XX点
- テスト: XX点
- セキュリティ: XX点
- パフォーマンス: XX点

### 改善優先度リスト
1. 最優先（Critical）
2. 高（High）
3. 中（Medium）
4. 低（Low）

## 使用例

### 全コード品質評価
```
/mcp-code-quality
プロジェクト全体のコード品質を評価し、改善提案をしてください
```

### Flask API品質評価
```
/mcp-code-quality
flask-app/内のAPIエンドポイントのコード品質を評価してください
```

### PowerShellスクリプト品質評価
```
/mcp-code-quality
powershell-scripts/のすべてのスクリプトの品質を評価してください
```

MCPを統合した多角的な品質評価を実施します。
