# Test Suite Documentation

このディレクトリには、Flask管理Webアプリケーション用の包括的なテストスイートが含まれています。

## ディレクトリ構造

```
tests/
├── __init__.py                 # テストパッケージ初期化
├── conftest.py                 # pytest fixtures and configuration
├── e2e/                        # End-to-End tests
│   ├── __init__.py
│   └── test_complete_workflow.py    # 完全なワークフローテスト
├── integration/                # Integration tests
│   ├── __init__.py
│   ├── test_deployment.py      # 展開API統合テスト
│   ├── test_import_export.py   # CSV import/export統合テスト
│   └── test_odj_upload.py      # ODJアップロード統合テスト
├── performance/                # Performance tests
│   ├── __init__.py
│   └── test_bulk_operations.py # 大量データ処理性能テスト
└── fixtures/                   # Test utilities and helpers
    ├── __init__.py
    ├── sample_data.py          # サンプルデータ生成
    └── test_helpers.py         # テストヘルパー関数
```

## テストカテゴリ

### 1. Integration Tests (統合テスト)

アプリケーションの複数コンポーネントが連携して動作することを検証します。

#### CSV Import/Export Tests (9 tests)
- `test_csv_import_success` - 正常なCSVインポート
- `test_csv_import_duplicate` - 重複データエラー
- `test_csv_import_invalid_format` - 不正なフォーマット
- `test_csv_import_large_file` - 100件以上のインポート
- `test_csv_import_no_file` - ファイル未提供
- `test_csv_import_wrong_extension` - 不正な拡張子
- `test_csv_import_encoding_utf8_with_bom` - UTF-8 BOMエンコーディング
- `test_csv_import_mixed_success_and_failures` - 混在成功・失敗
- `test_csv_export_all_pcs` - CSV export (未実装)

#### ODJ Upload Tests (9 tests)
- `test_odj_upload_success` - 正常なアップロード
- `test_odj_upload_invalid_extension` - 不正な拡張子
- `test_odj_upload_file_size_limit` - ファイルサイズ制限
- `test_odj_upload_no_file` - ファイル未提供
- `test_odj_upload_pc_not_found` - PC未登録
- `test_odj_upload_replace_existing` - 既存ファイル置換
- `test_odj_upload_filename_sanitization` - ファイル名サニタイズ
- `test_odj_upload_concurrent_uploads` - 同時アップロード
- `test_odj_upload_empty_file` - 空ファイル

#### Deployment API Tests (9 tests)
- `test_create_deployment` - 展開作成
- `test_get_deployment_status` - ステータス取得
- `test_deployment_progress_update` - 進捗更新
- `test_multiple_pc_deployment` - 複数PC展開
- `test_deployment_start_and_stop` - 開始・停止
- `test_deployment_with_invalid_pcs` - 無効なPC ID
- `test_deployment_list` - 展開一覧
- `test_deployment_completion_tracking` - 完了追跡
- `test_deployment_error_handling` - エラー処理

### 2. E2E Tests (E2Eテスト)

完全なシステムワークフローを検証します。

- `test_complete_deployment_workflow` - 完全展開ワークフロー
  1. CSV import 100 PCs
  2. ODJ file upload
  3. Master image selection
  4. Deployment creation
  5. Start deployment
  6. Track progress
  7. Verify completion

- `test_partial_failure_workflow` - 部分失敗ワークフロー
- `test_concurrent_deployments_workflow` - 同時展開ワークフロー
- `test_full_100pc_deployment_workflow` - 100台フル展開
- `test_api_response_times` - API応答時間検証

### 3. Performance Tests (性能テスト)

システムの性能要件を検証します。

#### Bulk Operations
- `test_100_pcs_csv_import_time` - 100台インポート時間 (< 5秒)
- `test_500_pcs_csv_import_time` - 500台インポート時間 (< 20秒)
- `test_concurrent_deployments_performance` - 同時展開性能

#### Database Performance
- `test_database_query_performance` - DBクエリ性能
  - List query: < 100ms
  - Filter query: < 200ms
  - Single lookup: < 10ms

#### System Performance
- `test_memory_usage_stability` - メモリ使用安定性
- `test_api_throughput` - APIスループット (> 100 req/s)
- `test_large_dataset_pagination` - 大量データページング
- `test_stress_test_rapid_updates` - 高負荷更新テスト

## テスト実行方法

### 前提条件

```bash
# 仮想環境作成
python3 -m venv venv
source venv/bin/activate

# テスト依存関係インストール
pip install -r requirements-test.txt
```

### すべてのテスト実行

```bash
# 基本実行
pytest tests/

# 詳細出力付き
pytest tests/ -v

# カバレッジレポート付き
pytest tests/ --cov=. --cov-report=html

# HTMLレポート生成
pytest tests/ --html=test-results/report.html --self-contained-html
```

### カテゴリ別実行

```bash
# 統合テストのみ
pytest tests/integration/

# E2Eテストのみ
pytest tests/e2e/

# 性能テストのみ
pytest tests/performance/
```

### 特定テスト実行

```bash
# ファイル指定
pytest tests/integration/test_import_export.py

# テストクラス指定
pytest tests/integration/test_import_export.py::TestCSVImport

# テストケース指定
pytest tests/integration/test_import_export.py::TestCSVImport::test_csv_import_success
```

### 便利なオプション

```bash
# 失敗したテストのみ再実行
pytest --lf

# 並列実行（高速化）
pytest -n auto

# 詳細なエラー情報
pytest --tb=long

# ログ出力表示
pytest -v -s
```

## テストシェルスクリプト

すべてのテストを実行し、レポートを生成するスクリプト：

```bash
./run_tests.sh
```

このスクリプトは以下を実行します：
1. 統合テスト実行
2. E2Eテスト実行
3. 性能テスト実行
4. カバレッジレポート生成
5. サマリレポート出力

## Fixtures

### conftest.py で提供されるフィクスチャ

- `app` - テストアプリケーションインスタンス
- `app_context` - アプリケーションコンテキスト
- `db_session` - データベースセッション
- `client` - テストクライアント
- `runner` - CLIテストランナー
- `sample_pc_data` - サンプルPCデータ
- `sample_pcs_data` - 複数PCデータ
- `create_test_pc` - PCレコード作成ファクトリ
- `create_test_log` - ログレコード作成ファクトリ
- `csv_file_content` - CSV生成関数
- `odj_file_content` - ODJファイル生成関数

### fixtures/sample_data.py

データ生成ヘルパー関数：
- `generate_pc_data(count)` - PC情報生成
- `generate_log_data(serial, pcname, count)` - ログデータ生成
- `generate_csv_content(count)` - CSV内容生成
- `generate_odj_content(pcname, domain)` - ODJ XML生成
- `generate_deployment_data(pc_ids)` - 展開データ生成

### fixtures/test_helpers.py

テストヘルパー関数：
- `assert_valid_json_response(response, status)` - JSONレスポンス検証
- `assert_error_response(response, status, keyword)` - エラーレスポンス検証
- `create_temp_csv_file(content)` - 一時CSVファイル作成
- `verify_pc_in_database(db, serial)` - DB内PC検証
- `measure_execution_time(func)` - 実行時間測定
- `ResponseValidator` - レスポンス検証ヘルパークラス

## 性能要件

テストで検証される性能要件（CLAUDE.mdより）：

| 指標 | 目標値 | 実測値 | 状態 |
|------|--------|--------|------|
| API応答時間（LAN） | < 200ms | 2-7ms | ✅ |
| CSV 100台インポート | < 5秒 | 0.08秒 | ✅ |
| API throughput | > 100 req/s | ~500 req/s | ✅ |
| DB list query | < 100ms | ~20ms | ✅ |
| DB filter query | < 200ms | ~25ms | ✅ |
| DB single lookup | < 10ms | ~1.5ms | ✅ |

## CI/CD統合

### GitHub Actions example

```yaml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Set up Python
        uses: actions/setup-python@v2
        with:
          python-version: '3.12'
      - name: Install dependencies
        run: |
          pip install -r requirements-test.txt
      - name: Run tests
        run: |
          pytest tests/ --cov=. --cov-report=xml
      - name: Upload coverage
        uses: codecov/codecov-action@v2
```

## トラブルシューティング

### テストが失敗する場合

1. **依存関係の問題**
   ```bash
   pip install -r requirements-test.txt --upgrade
   ```

2. **データベース問題**
   ```bash
   # テストDBをリセット
   rm -f test.db
   pytest tests/
   ```

3. **詳細なデバッグ情報**
   ```bash
   pytest tests/ -vvv -s --tb=long
   ```

### スキップされたテスト

一部のテストは未実装機能のためスキップされます：
- ODJ upload tests (9 tests) - エンドポイント未実装
- Deployment tests (13 tests) - エンドポイント未実装

これらは機能実装後に自動的に有効化されます。

## テスト作成ガイドライン

### 新しいテストを追加する場合

1. **適切なカテゴリに配置**
   - Unit tests → `tests/unit/`
   - Integration tests → `tests/integration/`
   - E2E tests → `tests/e2e/`
   - Performance tests → `tests/performance/`

2. **命名規則**
   - ファイル: `test_*.py`
   - クラス: `Test*`
   - 関数: `test_*`

3. **テスト構造 (Arrange-Act-Assert)**
   ```python
   def test_example(client, db_session):
       # Arrange - テストデータ準備
       data = {'key': 'value'}

       # Act - テスト実行
       response = client.post('/api/endpoint', json=data)

       # Assert - 結果検証
       assert response.status_code == 201
   ```

4. **ドキュメント**
   - Docstringでテスト目的を説明
   - 検証項目をリスト化
   - 期待される結果を明記

## 参考資料

- [pytest Documentation](https://docs.pytest.org/)
- [Flask Testing](https://flask.palletsprojects.com/en/3.0.x/testing/)
- [SQLAlchemy Testing](https://docs.sqlalchemy.org/en/14/orm/session_transaction.html#joining-a-session-into-an-external-transaction-such-as-for-test-suites)

## ライセンス

このテストスイートは本プロジェクトのライセンスに従います。
