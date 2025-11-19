# テストスイート

このディレクトリには、プロジェクトの各種テストが含まれています。

## 📁 ディレクトリ構造

```
tests/
├── unit/                  # ユニットテスト
│   ├── test_models.py    # データベースモデルのテスト
│   └── test_api.py       # API関数のテスト
├── integration/          # 統合テスト
│   ├── test_api_endpoints.py  # APIエンドポイントのテスト
│   └── test_database.py       # データベース統合テスト
└── e2e/                  # E2Eテスト
    └── test_setup_flow.py     # セットアップフロー全体のテスト
```

## 🧪 テストの種類

### ユニットテスト
個別の関数やメソッドの動作を検証

### 統合テスト
複数のコンポーネント間の連携を検証

### E2Eテスト
システム全体のワークフローを検証

## 🚀 実行方法

### 全テスト実行
```bash
pytest
```

### ユニットテストのみ
```bash
pytest tests/unit/
```

### 統合テストのみ
```bash
pytest tests/integration/
```

### E2Eテストのみ
```bash
pytest tests/e2e/
```

### カバレッジレポート付き
```bash
pytest --cov=flask-app --cov-report=html
```

## 📊 カバレッジ目標

- ユニットテスト: 90%以上
- 統合テスト: 80%以上
- E2Eテスト: 主要フロー100%

## 📝 実装状況

✅ ディレクトリ構造作成完了
⏳ テスト実装は `/test-all` で実施
