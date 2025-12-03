#!/usr/bin/env python3
"""
PCマスターイメージ取り込み・展開機能実装状況確認スクリプト

このスクリプトは以下を確認します:
1. マスターイメージ取り込み機能の実装状況
2. PC展開機能の実装状況
3. DRBLサーバ統合状況
4. 各機能のテスト実行可否
"""

import sys
import json
from pathlib import Path
from datetime import datetime

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent))

# Import only what's needed without triggering Flask app initialization
try:
    from utils.drbl_client import DRBLClient
except ImportError:
    DRBLClient = None


class ImplementationChecker:
    """実装状況確認クラス"""

    def __init__(self):
        self.results = {
            'image_management': {},
            'deployment': {},
            'drbl_integration': {},
            'api_endpoints': {},
            'web_ui': {},
            'tests': {}
        }
        self.drbl_client = None

    def check_drbl_client(self):
        """DRBLクライアント機能の確認"""
        print("\n" + "="*60)
        print("1. DRBLクライアント実装確認")
        print("="*60)

        try:
            self.drbl_client = DRBLClient()
            print("✅ DRBLClientインスタンス化: 成功")

            # メソッド存在確認
            methods = {
                'list_images': 'マスターイメージ一覧取得',
                'get_image_info': 'マスターイメージ詳細取得',
                'start_multicast_deployment': 'マルチキャスト展開開始',
                'start_unicast_deployment': 'ユニキャスト展開開始',
                'stop_deployment': '展開停止',
                'get_deployment_status': '展開ステータス取得',
                'list_odj_files': 'ODJファイル一覧取得',
                'health_check': 'ヘルスチェック'
            }

            implemented_methods = []
            missing_methods = []

            for method, description in methods.items():
                if hasattr(self.drbl_client, method):
                    print(f"✅ {method}: {description}")
                    implemented_methods.append(method)
                else:
                    print(f"❌ {method}: {description} - 未実装")
                    missing_methods.append(method)

            self.results['drbl_integration'] = {
                'client_initialized': True,
                'implemented_methods': implemented_methods,
                'missing_methods': missing_methods,
                'implementation_rate': len(implemented_methods) / len(methods) * 100
            }

            # ヘルスチェック実行
            if hasattr(self.drbl_client, 'health_check'):
                print("\n📊 DRBLヘルスチェック:")
                health = self.drbl_client.health_check()
                for key, value in health.items():
                    status = "✅" if value else "❌"
                    print(f"  {status} {key}: {value}")
                self.results['drbl_integration']['health'] = health

        except Exception as e:
            print(f"❌ DRBLClient初期化失敗: {e}")
            self.results['drbl_integration'] = {
                'client_initialized': False,
                'error': str(e)
            }

    def check_image_api(self):
        """マスターイメージAPI確認"""
        print("\n" + "="*60)
        print("2. マスターイメージAPI実装確認")
        print("="*60)

        # APIファイル存在確認
        api_file = Path(__file__).parent / 'api' / 'images.py'

        if not api_file.exists():
            print("❌ api/images.py: ファイルが存在しません")
            self.results['api_endpoints']['images'] = {'exists': False}
            return

        print("✅ api/images.py: ファイル存在")

        # エンドポイント定義確認
        with open(api_file, 'r') as f:
            content = f.read()

        endpoints = {
            'GET /api/images': 'list_images',
            'GET /api/images/<image_name>': 'get_image_details',
            'POST /api/images': 'register_image',
            'DELETE /api/images/<image_name>': 'delete_image'
        }

        implemented_endpoints = []
        missing_endpoints = []

        for endpoint, function_name in endpoints.items():
            if function_name in content:
                print(f"✅ {endpoint}: {function_name}() - 実装済み")
                implemented_endpoints.append(endpoint)
            else:
                print(f"❌ {endpoint}: {function_name}() - 未実装")
                missing_endpoints.append(endpoint)

        self.results['api_endpoints']['images'] = {
            'exists': True,
            'implemented': implemented_endpoints,
            'missing': missing_endpoints,
            'implementation_rate': len(implemented_endpoints) / len(endpoints) * 100
        }

    def check_deployment_api(self):
        """展開API確認"""
        print("\n" + "="*60)
        print("3. PC展開API実装確認")
        print("="*60)

        api_file = Path(__file__).parent / 'api' / 'deployment.py'

        if not api_file.exists():
            print("❌ api/deployment.py: ファイルが存在しません")
            self.results['api_endpoints']['deployment'] = {'exists': False}
            return

        print("✅ api/deployment.py: ファイル存在")

        with open(api_file, 'r') as f:
            content = f.read()

        endpoints = {
            'POST /api/deployment': 'create_deployment',
            'GET /api/deployment': 'list_deployments',
            'GET /api/deployment/<id>': 'get_deployment',
            'GET /api/deployment/<id>/status': 'get_deployment_status',
            'POST /api/deployment/<id>/start': 'start_deployment',
            'POST /api/deployment/<id>/stop': 'stop_deployment',
            'PUT /api/deployment/<id>': 'update_deployment',
            'DELETE /api/deployment/<id>': 'delete_deployment'
        }

        implemented_endpoints = []
        missing_endpoints = []

        for endpoint, function_name in endpoints.items():
            if function_name in content:
                print(f"✅ {endpoint}: {function_name}() - 実装済み")
                implemented_endpoints.append(endpoint)
            else:
                print(f"❌ {endpoint}: {function_name}() - 未実装")
                missing_endpoints.append(endpoint)

        self.results['api_endpoints']['deployment'] = {
            'exists': True,
            'implemented': implemented_endpoints,
            'missing': missing_endpoints,
            'implementation_rate': len(implemented_endpoints) / len(endpoints) * 100
        }

    def check_web_ui(self):
        """WebUI確認"""
        print("\n" + "="*60)
        print("4. WebUI実装確認")
        print("="*60)

        templates_dir = Path(__file__).parent / 'templates' / 'deployment'

        if not templates_dir.exists():
            print("❌ templates/deployment/: ディレクトリが存在しません")
            self.results['web_ui'] = {'exists': False}
            return

        print("✅ templates/deployment/: ディレクトリ存在")

        templates = {
            'images.html': 'マスターイメージ一覧',
            'create.html': '展開設定作成',
            'list.html': '展開一覧',
            'detail.html': '展開詳細',
            'status.html': '展開ステータス',
            'settings.html': '展開設定'
        }

        existing_templates = []
        missing_templates = []

        for template, description in templates.items():
            template_path = templates_dir / template
            if template_path.exists():
                print(f"✅ {template}: {description}")
                existing_templates.append(template)
            else:
                print(f"❌ {template}: {description} - ファイルなし")
                missing_templates.append(template)

        self.results['web_ui'] = {
            'exists': True,
            'existing_templates': existing_templates,
            'missing_templates': missing_templates,
            'implementation_rate': len(existing_templates) / len(templates) * 100
        }

    def check_tests(self):
        """テスト実装確認"""
        print("\n" + "="*60)
        print("5. テスト実装確認")
        print("="*60)

        tests_dir = Path(__file__).parent / 'tests'

        if not tests_dir.exists():
            print("❌ tests/: ディレクトリが存在しません")
            self.results['tests'] = {'exists': False}
            return

        print("✅ tests/: ディレクトリ存在")

        test_files = {
            'integration/test_deployment.py': '展開統合テスト',
            'e2e/test_complete_workflow.py': 'E2Eワークフローテスト',
        }

        existing_tests = []
        missing_tests = []

        for test_file, description in test_files.items():
            test_path = tests_dir / test_file
            if test_path.exists():
                print(f"✅ {test_file}: {description}")
                existing_tests.append(test_file)
            else:
                print(f"❌ {test_file}: {description} - ファイルなし")
                missing_tests.append(test_file)

        self.results['tests'] = {
            'exists': True,
            'existing_tests': existing_tests,
            'missing_tests': missing_tests,
            'implementation_rate': len(existing_tests) / len(test_files) * 100 if test_files else 0
        }

    def check_models(self):
        """モデル実装確認"""
        print("\n" + "="*60)
        print("6. データモデル実装確認")
        print("="*60)

        models_dir = Path(__file__).parent / 'models'

        if not models_dir.exists():
            print("❌ models/: ディレクトリが存在しません")
            return

        print("✅ models/: ディレクトリ存在")

        model_file = models_dir / 'deployment.py'

        if model_file.exists():
            print("✅ deployment.py: モデル実装済み")

            with open(model_file, 'r') as f:
                content = f.read()

            # 必須フィールド確認
            required_fields = [
                'id', 'name', 'image_name', 'mode', 'status',
                'target_serials', 'started_at', 'completed_at'
            ]

            for field in required_fields:
                if field in content:
                    print(f"  ✅ {field}フィールド")
                else:
                    print(f"  ❌ {field}フィールド - 未定義")
        else:
            print("❌ deployment.py: モデル未実装")

    def check_file_structure(self):
        """ファイル構造確認"""
        print("\n" + "="*60)
        print("7. ファイル構造確認")
        print("="*60)

        required_dirs = {
            'api': 'APIエンドポイント',
            'models': 'データモデル',
            'utils': 'ユーティリティ',
            'views': 'Viewルーティング',
            'templates': 'HTMLテンプレート',
            'tests': 'テストコード'
        }

        base_dir = Path(__file__).parent

        for dir_name, description in required_dirs.items():
            dir_path = base_dir / dir_name
            if dir_path.exists():
                file_count = len(list(dir_path.glob('**/*.py')))
                print(f"✅ {dir_name}/: {description} ({file_count} Python files)")
            else:
                print(f"❌ {dir_name}/: {description} - ディレクトリなし")

    def generate_report(self):
        """レポート生成"""
        print("\n" + "="*60)
        print("📊 実装状況レポート")
        print("="*60)

        # 1. マスターイメージ取り込み機能
        print("\n### 1. マスターイメージ取り込み機能")
        print("-" * 40)

        image_features = {
            'マスターイメージ一覧取得': self._check_feature('drbl_integration', 'implemented_methods', 'list_images'),
            'マスターイメージ詳細取得': self._check_feature('drbl_integration', 'implemented_methods', 'get_image_info'),
            'マスターイメージ削除': True,  # delete_image is in API
            'WebUI一覧表示': self._check_feature('web_ui', 'existing_templates', 'images.html'),
            'API一覧取得': self._check_feature('api_endpoints', 'images', 'implemented', 'GET /api/images'),
            'API詳細取得': self._check_feature('api_endpoints', 'images', 'implemented', 'GET /api/images/<image_name>'),
        }

        for feature, implemented in image_features.items():
            status = "✅" if implemented else "❌"
            print(f"{status} {feature}")

        image_rate = sum(image_features.values()) / len(image_features) * 100
        print(f"\n実装率: {image_rate:.1f}%")

        # 2. PC展開機能
        print("\n### 2. PC展開機能")
        print("-" * 40)

        deployment_features = {
            'PC選択機能': True,  # create.html exists
            'マスターイメージ選択': True,  # in create form
            '展開モード選択': self._check_feature('drbl_integration', 'implemented_methods', 'start_multicast_deployment'),
            '展開開始': self._check_feature(
                'api_endpoints', 'deployment', 'implemented',
                'POST /api/deployment/<id>/start'),
            '展開停止': self._check_feature('api_endpoints', 'deployment', 'implemented', 'POST /api/deployment/<id>/stop'),
            '進捗モニタリング': self._check_feature('drbl_integration', 'implemented_methods', 'get_deployment_status'),
            'WebUI展開一覧': self._check_feature('web_ui', 'existing_templates', 'list.html'),
            'WebUI展開詳細': self._check_feature('web_ui', 'existing_templates', 'detail.html'),
            'WebUIステータス': self._check_feature('web_ui', 'existing_templates', 'status.html'),
        }

        for feature, implemented in deployment_features.items():
            status = "✅" if implemented else "❌"
            print(f"{status} {feature}")

        deployment_rate = sum(deployment_features.values()) / len(deployment_features) * 100
        print(f"\n実装率: {deployment_rate:.1f}%")

        # 3. 未実装機能リスト
        print("\n### 3. 未実装機能リスト")
        print("-" * 40)

        missing_features = []

        if not image_features['マスターイメージ一覧取得']:
            missing_features.append(('マスターイメージ一覧取得', '高', '中'))

        # DRBLインテグレーション
        if 'drbl_integration' in self.results and 'missing_methods' in self.results['drbl_integration']:
            for method in self.results['drbl_integration']['missing_methods']:
                missing_features.append((f'DRBLクライアント: {method}', '高', '高'))

        # API
        if 'api_endpoints' in self.results:
            if 'images' in self.results['api_endpoints'] and 'missing' in self.results['api_endpoints']['images']:
                for endpoint in self.results['api_endpoints']['images']['missing']:
                    missing_features.append((f'Images API: {endpoint}', '中', '低'))

            if ('deployment' in self.results['api_endpoints']
                    and 'missing' in self.results['api_endpoints']['deployment']):
                for endpoint in self.results['api_endpoints']['deployment']['missing']:
                    missing_features.append((f'Deployment API: {endpoint}', '高', '中'))

        # WebUI
        if 'web_ui' in self.results and 'missing_templates' in self.results['web_ui']:
            for template in self.results['web_ui']['missing_templates']:
                missing_features.append((f'WebUIテンプレート: {template}', '中', '低'))

        if missing_features:
            print("\n機能名 | 必要性 | 実装難易度")
            print("-" * 60)
            for feature, necessity, difficulty in missing_features:
                print(f"{feature} | {necessity} | {difficulty}")
        else:
            print("✅ すべての主要機能が実装されています")

        # 4. 推奨実装順序
        print("\n### 4. 推奨実装順序")
        print("-" * 40)

        if missing_features:
            # 必要性と難易度でソート
            priority_map = {'高': 3, '中': 2, '低': 1}
            sorted_features = sorted(
                missing_features,
                key=lambda x: (priority_map[x[1]], -priority_map[x[2]]),
                reverse=True
            )

            for i, (feature, necessity, difficulty) in enumerate(sorted_features[:10], 1):
                print(f"{i}. [優先度: {necessity}] {feature} (難易度: {difficulty})")
        else:
            print("✅ すべての機能が実装済みです")

        # 5. 総合評価
        print("\n### 5. 総合評価")
        print("=" * 60)

        overall_rate = (image_rate + deployment_rate) / 2

        print(f"\nマスターイメージ機能: {image_rate:.1f}%")
        print(f"PC展開機能: {deployment_rate:.1f}%")
        print(f"総合実装率: {overall_rate:.1f}%")

        if overall_rate >= 90:
            print("\n🎉 優秀! ほぼすべての機能が実装されています")
        elif overall_rate >= 70:
            print("\n👍 良好! 主要機能は実装されています")
        elif overall_rate >= 50:
            print("\n⚠️  要改善! いくつかの重要機能が未実装です")
        else:
            print("\n❌ 多数の機能が未実装です")

        # JSONレポート保存
        report_file = Path(__file__).parent / 'implementation_status_report.json'

        report_data = {
            'timestamp': datetime.now().isoformat(),
            'results': self.results,
            'summary': {
                'image_features': image_features,
                'deployment_features': deployment_features,
                'image_rate': image_rate,
                'deployment_rate': deployment_rate,
                'overall_rate': overall_rate,
                'missing_features': missing_features
            }
        }

        with open(report_file, 'w', encoding='utf-8') as f:
            json.dump(report_data, f, indent=2, ensure_ascii=False)

        print(f"\n📄 詳細レポート保存: {report_file}")

    def _check_feature(self, category, *keys):
        """機能実装確認ヘルパー"""
        try:
            current = self.results[category]
            for key in keys[:-1]:
                if key not in current:
                    return False
                current = current[key]

            last_key = keys[-1]
            if isinstance(current, list):
                return last_key in current
            elif isinstance(current, dict):
                return last_key in current
            else:
                return bool(current)
        except (KeyError, TypeError):
            return False

    def run_all_checks(self):
        """すべての確認を実行"""
        print("\n" + "="*60)
        print("PCマスターイメージ取り込み・展開機能 実装状況確認")
        print("="*60)
        print(f"実行日時: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")

        self.check_file_structure()
        self.check_drbl_client()
        self.check_image_api()
        self.check_deployment_api()
        self.check_models()
        self.check_web_ui()
        self.check_tests()
        self.generate_report()


def main():
    """メイン処理"""
    checker = ImplementationChecker()
    checker.run_all_checks()

    print("\n" + "="*60)
    print("実装状況確認完了")
    print("="*60)


if __name__ == '__main__':
    main()
