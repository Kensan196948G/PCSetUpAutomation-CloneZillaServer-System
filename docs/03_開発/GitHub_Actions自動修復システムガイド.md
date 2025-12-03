# GitHub Actions 自動エラー検知・修復システム完全ガイド

**作成日**: 2025-12-03
**バージョン**: 1.0
**対象**: 開発者・運用担当者

---

## 📋 目次

1. [概要](#概要)
2. [システムアーキテクチャ](#システムアーキテクチャ)
3. [自動検知されるエラー](#自動検知されるエラー)
4. [自動修復機能](#自動修復機能)
5. [30分間隔無限ループの仕組み](#30分間隔無限ループの仕組み)
6. [GitHub Issue自動作成](#github-issue自動作成)
7. [使用方法](#使用方法)
8. [トラブルシューティング](#トラブルシューティング)

---

## 概要

本プロジェクトには、**セルフヒーリング（自己修復）システム**が組み込まれています。

### 主な特徴

- 🔄 **30分間隔で無限実行**: GitHub Actionsのcronで自動実行
- 🔍 **包括的エラー検知**: 構文エラー、テスト失敗、Import問題、コード品質
- 🔧 **インテリジェント修復**: 15回までのリトライループで段階的に修復
- 📝 **自動Issue作成**: 修復できないエラーをGitHub Issueとして報告
- ✅ **自動クローズ**: 次回実行時にエラーが解消されていればIssue自動クローズ
- 💾 **自動コミット**: 修復したコードを自動的にリポジトリへプッシュ

---

## システムアーキテクチャ

```
┌─────────────────────────────────────────────────────────┐
│ GitHub Actions Scheduler（cron: */30 * * * *）          │
│ 30分ごとに自動起動                                       │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│ Job 1: Auto-Heal（メイン処理）                          │
│                                                         │
│ ┌─────────────────────────────────────────────────────┐│
│ │ ループ 1/15                                         ││
│ │   ├─ エラー検知（4種類）                            ││
│ │   ├─ 自動修復試行                                   ││
│ │   └─ 結果記録                                       ││
│ └─────────────────────────────────────────────────────┘│
│                          ↓                              │
│ ┌─────────────────────────────────────────────────────┐│
│ │ ループ 2/15                                         ││
│ │   ├─ 再度エラー検知                                 ││
│ │   ├─ 自動修復試行                                   ││
│ │   └─ 結果記録                                       ││
│ └─────────────────────────────────────────────────────┘│
│                          ...                            │
│                                                         │
│ ┌─────────────────────────────────────────────────────┐│
│ │ ループ 15/15（または全エラー解消で早期終了）        ││
│ └─────────────────────────────────────────────────────┘│
│                          ↓                              │
│ ┌─────────────────────────────────────────────────────┐│
│ │ 修復結果の判定                                      ││
│ │   ├─ 全て修復 → コミット・プッシュ → Issue自動クローズ
│ │   └─ 一部失敗 → GitHub Issue自動作成              ││
│ └─────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────┘
        ↓ 30分待機 ↓
┌─────────────────────────────────────────────────────────┐
│ 次回の自動実行（無限ループ）                             │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│ Job 2: Health-Check（並列実行）                         │
│   ├─ Python構文チェック                                │
│   ├─ Lintチェック                                      │
│   ├─ テストスイート実行                                │
│   ├─ セキュリティチェック（bandit）                    │
│   └─ 依存関係脆弱性チェック（safety）                  │
└─────────────────────────────────────────────────────────┘
```

---

## 自動検知されるエラー

### 1. Python構文エラー（Critical）

**検知ツール**: flake8（E9、F63、F7、F82）

**検知例**:
```python
# E9: 構文エラー
def function(
    # 閉じ括弧なし

# F63: 無効なprint文
print "Hello"  # Python 3では不可

# F7: 未定義変数
result = undefined_variable

# F82: 未定義名
return unknown_function()
```

---

### 2. テスト失敗（High）

**検知ツール**: pytest

**検知例**:
- ユニットテストの失敗
- 統合テストの失敗
- アサーションエラー
- ImportError、ModuleNotFoundError

---

### 3. Import エラー（Medium）

**検知ツール**: pyflakes

**検知例**:
```python
# 未使用インポート
import os  # 使用されていない
from flask import Flask, request  # requestが未使用

# 未定義名
result = datetime.now()  # datetimeがインポートされていない
```

---

### 4. コード品質問題（Low）

**検知ツール**: flake8

**検知例**:
- E501: 行が長すぎる（>79文字）
- W503: 演算子の前の改行
- F401: インポートされているが未使用

---

## 自動修復機能

### 1. 未使用インポートの削除

**対応エラー**: `imported but unused`

**修復例**:
```python
# 修復前
import os  # 未使用
from flask import Flask, request  # requestが未使用

app = Flask(__name__)

# 修復後
from flask import Flask

app = Flask(__name__)
```

**修復方法**: 該当行を自動削除

---

### 2. インデントエラーの修正

**対応エラー**: `indentation error`

**修復例**:
```python
# 修復前
def function():
 return True  # インデント不足

# 修復後
def function():
    return True  # 4スペースに修正
```

**修復方法**: autopep8による自動修正

---

### 3. 不足インポートの追加

**対応エラー**: `undefined name`

**修復例**:
```python
# 修復前
def get_time():
    return datetime.now()  # datetimeが未定義

# 修復後
from datetime import datetime

def get_time():
    return datetime.now()
```

**修復方法**: 一般的なインポートマッピングから自動追加

**対応マッピング**:
```python
{
    'Flask': 'from flask import Flask',
    'request': 'from flask import request',
    'jsonify': 'from flask import jsonify',
    'db': 'from models import db',
    'PCMaster': 'from models import PCMaster',
    'SetupLog': 'from models import SetupLog',
    'datetime': 'from datetime import datetime',
    'Optional': 'from typing import Optional',
    'List': 'from typing import List',
    'Dict': 'from typing import Dict',
}
```

---

### 4. 自動フォーマット

**対応エラー**: コードスタイル全般

**修復ツール**: black

**修復例**:
```python
# 修復前
def   function(  x,y  ):
      return    x+y

# 修復後
def function(x, y):
    return x + y
```

---

## 30分間隔無限ループの仕組み

### cron設定

```yaml
on:
  schedule:
    - cron: '*/30 * * * *'  # 30分ごとに実行
```

**実行タイミング**:
- 00:00、00:30、01:00、01:30、02:00...
- **24時間365日稼働**

### 実行フロー

```
00:00 → 実行開始
     ├─ エラー検知・修復（最大15回ループ）
     ├─ Issue作成/クローズ
     └─ 実行完了

00:30 → 実行開始（前回の続きから）
     ├─ 前回修復できなかったエラーを再検知
     ├─ 再度修復試行
     └─ 実行完了

01:00 → 実行開始
     ...（無限ループ）
```

### 15回リトライループの詳細

```python
for iteration in range(1, 16):  # 1〜15回
    # エラー検知
    errors = detect_all_errors()

    if not errors:
        print("✅ エラーなし")
        break  # 早期終了

    # 自動修復
    fixed, remaining = auto_heal(errors)

    if fixed == 0 and iteration > 1:
        print("⚠️ 修復不可能")
        break  # 早期終了

    # 次の反復へ
```

**早期終了条件**:
1. 全てのエラーが解消された
2. 修復が進まなくなった（2回連続で修復数0）

---

## GitHub Issue自動作成

### Issue作成条件

以下の条件で自動的にIssueが作成されます：

1. **15回のループ完了後もエラーが残存**
2. **修復が不可能と判断された**

### Issue内容

```markdown
## 🚨 自動修復できなかったエラー

**検出日時**: 2025-12-03T10:00:00Z
**ワークフロー実行**: [#123456](リンク)

---

## 📊 統計

- 総エラー数: 10個
- 修復済み: 7個
- **未修復**: 3個
- 反復回数: 15回

---

## ❌ 未修復エラー一覧

### エラー 1: syntax_error

**ファイル**: `flask-app/api/pcinfo.py`
**行**: 45
**メッセージ**:
```
invalid syntax
```

**修復試行回数**: 15回

---

## 🔧 推奨対応

1. ローカル環境でエラーを再現
2. 手動で修正
3. `/commit-push-pr-merge`
```

### Issue自動クローズ

次回の実行（30分後）で：
- エラーが解消されている → Issue に成功コメント追加 → 自動クローズ
- エラーがまだ残っている → 新しいコメント追加

---

## 使用方法

### 自動実行（推奨）

何もする必要はありません！30分ごとに自動実行されます。

### 手動実行（GitHub Actions）

1. GitHubリポジトリページを開く
2. **Actions** タブをクリック
3. **Auto Error Detection & Healing System** を選択
4. **Run workflow** をクリック
5. オプション設定:
   - `max_iterations`: 最大反復回数（デフォルト: 15）
6. **Run workflow** をクリック

### ローカル実行

```bash
# 依存関係インストール
pip install flake8 pyflakes autopep8 black pytest

# スクリプト実行
python .github/scripts/auto_heal.py --max-iterations 15

# 結果確認
cat auto_heal_summary.json
cat auto_heal_detailed.log
```

---

## トラブルシューティング

### GitHub Actionsが実行されない

**原因**:
- リポジトリがプライベートでActionsが無効
- cron設定の構文エラー
- ワークフローファイルの配置ミス

**解決方法**:
```bash
# 1. GitHub Settings > Actions > General
#    "Allow all actions and reusable workflows" を選択

# 2. ワークフローファイル確認
cat .github/workflows/auto-heal.yml

# 3. 手動実行でテスト
# GitHub > Actions > Run workflow
```

### 修復スクリプトがエラーを出す

**原因**:
- 依存パッケージ不足
- Pythonバージョンの不一致

**解決方法**:
```bash
# ローカルでデバッグ
python -m pip install flake8 pyflakes autopep8 black pytest
python .github/scripts/auto_heal.py --max-iterations 1
```

### Issueが大量に作成される

**原因**:
- 修復不可能なエラーが継続的に発生

**解決方法**:
```bash
# 1. Issueを確認して手動修正
# 2. 一時的にワークフローを無効化
git mv .github/workflows/auto-heal.yml .github/workflows/auto-heal.yml.disabled

# 3. 修正後に再有効化
git mv .github/workflows/auto-heal.yml.disabled .github/workflows/auto-heal.yml
```

---

## 実行例

### 成功例（全エラー修復）

```
=== 自動エラー検知・修復システム開始 ===
最大反復回数: 15

🔄 反復 1/15
🔍 全エラー検知を開始
  → 5個の構文エラーを検出
  → 2個のImportエラーを検出

🔧 自動修復を開始
  ✅ 未使用インポートを削除: flask-app/api/pcinfo.py:3
  ✅ 未使用インポートを削除: flask-app/models/pc_master.py:5
  ✅ 修復完了: 2個のエラーを修正

🔄 反復 2/15
🔍 全エラー検知を開始
  → 3個の構文エラーを検出

🔧 自動修復を開始
  ✅ インデントエラーを修正: flask-app/api/log.py
  ✅ 修復完了: 3個のエラーを修正

🔄 反復 3/15
🔍 全エラー検知を開始
  → 0個のエラーを検出

✅ 全てのエラーが修復されました！

📊 最終結果
総エラー数: 7
修復済み: 7
残存エラー: 0
反復回数: 3/15
```

### 一部失敗例（Issue作成）

```
=== 自動エラー検知・修復システム開始 ===

（15回のループ実行...）

⚠️ 最大反復回数(15)に達しました
   残存エラー: 2個

📊 最終結果
総エラー数: 10
修復済み: 8
残存エラー: 2
反復回数: 15/15

→ GitHub Issue作成: 「🚨 自動修復失敗 - 2個のエラーが残存」
```

---

## 設定ファイル

### .github/workflows/auto-heal.yml

**トリガー設定**:
```yaml
on:
  schedule:
    - cron: '*/30 * * * *'  # 30分間隔
  workflow_dispatch:        # 手動実行可能
  push:                     # プッシュ時も実行
    branches: [main, develop]
  pull_request:             # PR時も実行
    branches: [main]
```

**環境変数**:
```yaml
env:
  MAX_HEAL_ITERATIONS: 15
  PYTHON_VERSION: '3.12'
```

---

### .github/scripts/auto_heal.py

**メインクラス**:
- `ErrorDetector`: エラー検知
- `ErrorHealer`: 自動修復
- `AutoHealSystem`: システム全体の制御

**実行コマンド**:
```bash
python auto_heal.py \
  --max-iterations 15 \
  --github-token "$GITHUB_TOKEN" \
  --repo "owner/repo" \
  --run-id "123456"
```

---

## アーティファクト

各実行で以下のアーティファクトが保存されます（30日間保持）：

1. **auto_heal_summary.json** - 修復結果サマリー
2. **auto_heal_detailed.log** - 詳細ログ
3. **auto_heal_fixes.patch** - 適用された修正のパッチファイル

**ダウンロード方法**:
```
GitHub > Actions > 実行を選択 > Artifacts
```

---

## パフォーマンス考慮事項

### 実行時間

- **平均実行時間**: 3-5分（エラー数による）
- **最大実行時間**: 10-15分（15回フルループ）

### リソース使用量

- **CPUクレジット**: 無料枠（月2,000分）で十分対応可能
- **ストレージ**: アーティファクト保持（30日）で約100MB/月

### コスト削減

```yaml
# パブリックリポジトリ: 無料
# プライベートリポジトリ: 月2,000分まで無料

# 必要に応じてcron間隔を調整
schedule:
  - cron: '0 */2 * * *'  # 2時間ごとに変更
```

---

## セキュリティ考慮事項

### Permissions設定

```yaml
permissions:
  contents: write      # コミット・プッシュ用
  issues: write        # Issue作成用
  pull-requests: write # PR作成用
```

### シークレット管理

- `GITHUB_TOKEN`: 自動提供（追加設定不要）
- カスタムシークレットは不要

### 自動修復の制限

- `.gitignore` 対象ファイルは変更しない
- `production/` ディレクトリは変更しない（安全性重視）
- データベースファイル（*.db）は変更しない

---

## FAQ

### Q1: 30分間隔を変更できますか？

**A**: はい、`.github/workflows/auto-heal.yml` のcron設定を変更してください。

```yaml
# 1時間ごと
- cron: '0 * * * *'

# 2時間ごと
- cron: '0 */2 * * *'

# 1日1回（午前2時）
- cron: '0 2 * * *'
```

### Q2: 特定のエラーを無視できますか？

**A**: はい、`.github/scripts/auto_heal.py` の `ErrorDetector` クラスを修正してください。

### Q3: 修復スクリプトをカスタマイズできますか？

**A**: はい、`ErrorHealer` クラスに新しい修復メソッドを追加できます。

### Q4: ローカルで同じチェックを実行できますか？

**A**: はい、以下のコマンドで実行できます：

```bash
python .github/scripts/auto_heal.py --max-iterations 15
```

---

## 関連ドキュメント

- [GitHub Actions公式ドキュメント](https://docs.github.com/en/actions)
- [CHANGELOG.md](../../CHANGELOG.md)
- [トラブルシューティング集](../08_トラブルシューティング/トラブルシューティング集.md)

---

## 更新履歴

| バージョン | 日付 | 変更内容 |
|----------|------|---------|
| 1.0 | 2025-12-03 | 初版作成 |

---

**作成者**: Claude Code + DevOps Engineer Agent
**最終更新**: 2025-12-03
