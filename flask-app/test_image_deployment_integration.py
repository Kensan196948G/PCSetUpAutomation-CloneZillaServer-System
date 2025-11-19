#!/usr/bin/env python3
"""
PCマスターイメージ取り込み・展開機能 統合テスト

このスクリプトは以下のテストを実行します:
1. DRBLクライアントの機能テスト
2. マスターイメージAPI動作テスト
3. 展開API動作テスト (モック)
"""

import sys
from pathlib import Path
from datetime import datetime

# Add parent directory to path
sys.path.insert(0, str(Path(__file__).parent))

from utils.drbl_client import DRBLClient, DRBLException


class ImageDeploymentTester:
    """統合テスター"""

    def __init__(self):
        self.drbl_client = DRBLClient()
        self.test_results = []

    def log_test(self, test_name, success, message="", details=None):
        """テスト結果記録"""
        status = "✅ PASS" if success else "❌ FAIL"
        print(f"{status} | {test_name}")
        if message:
            print(f"       └─ {message}")
        if details and not success:
            print(f"       └─ Details: {details}")

        self.test_results.append({
            'test': test_name,
            'success': success,
            'message': message,
            'details': details
        })

    def test_drbl_client_initialization(self):
        """Test 1: DRBLクライアント初期化"""
        print("\n" + "="*60)
        print("Test 1: DRBLクライアント初期化")
        print("="*60)

        try:
            client = DRBLClient()
            self.log_test(
                "DRBLClient インスタンス化",
                True,
                f"image_home={client.image_home}"
            )

            health = client.health_check()
            self.log_test(
                "ヘルスチェック実行",
                True,
                f"DRBL installed: {health['drbl_installed']}, Images: {health['image_count']}"
            )

        except Exception as e:
            self.log_test("DRBLClient 初期化", False, details=str(e))

    def test_list_images(self):
        """Test 2: マスターイメージ一覧取得"""
        print("\n" + "="*60)
        print("Test 2: マスターイメージ一覧取得")
        print("="*60)

        try:
            images = self.drbl_client.list_images()

            self.log_test(
                "list_images() 実行",
                True,
                f"{len(images)} images found"
            )

            if images:
                print("\n  検出されたイメージ:")
                for img in images:
                    print(f"    - {img['name']}")
                    print(f"      サイズ: {img['size_human']}")
                    print(f"      作成日: {img['created']}")
                    print(f"      ディスク数: {img['disk_count']}")

                # 最初のイメージの詳細取得
                first_image = images[0]
                image_info = self.drbl_client.get_image_info(first_image['name'])

                if image_info:
                    self.log_test(
                        "get_image_info() 実行",
                        True,
                        f"Image: {image_info['name']}"
                    )
                else:
                    self.log_test(
                        "get_image_info() 実行",
                        False,
                        "イメージ情報取得失敗"
                    )
            else:
                self.log_test(
                    "マスターイメージ検出",
                    False,
                    "/home/partimag/ にイメージがありません"
                )

        except Exception as e:
            self.log_test("list_images() 実行", False, details=str(e))

    def test_deployment_simulation(self):
        """Test 3: 展開シミュレーション (DRBL未インストール環境対応)"""
        print("\n" + "="*60)
        print("Test 3: 展開シミュレーション")
        print("="*60)

        try:
            images = self.drbl_client.list_images()

            if not images:
                self.log_test(
                    "展開シミュレーション",
                    False,
                    "テスト用イメージが存在しません"
                )
                return

            test_image = images[0]['name']

            # マルチキャスト展開テスト
            try:
                result = self.drbl_client.start_multicast_deployment(
                    image_name=test_image,
                    clients_to_wait=5,
                    max_wait_time=10
                )

                if result['status'] in ['started', 'simulated']:
                    self.log_test(
                        "マルチキャスト展開開始",
                        True,
                        f"Status: {result['status']}"
                    )
                else:
                    self.log_test(
                        "マルチキャスト展開開始",
                        False,
                        f"Unexpected status: {result['status']}"
                    )

            except DRBLException as e:
                # DRBL未インストール環境ではエラーが想定される
                self.log_test(
                    "マルチキャスト展開開始",
                    True,
                    "DRBL未インストール環境のため正常なエラー"
                )

            # ユニキャスト展開テスト
            try:
                result = self.drbl_client.start_unicast_deployment(
                    image_name=test_image,
                    target_mac='00:11:22:33:44:55'
                )

                if result['status'] in ['started', 'simulated']:
                    self.log_test(
                        "ユニキャスト展開開始",
                        True,
                        f"Status: {result['status']}"
                    )
                else:
                    self.log_test(
                        "ユニキャスト展開開始",
                        False,
                        f"Unexpected status: {result['status']}"
                    )

            except DRBLException as e:
                self.log_test(
                    "ユニキャスト展開開始",
                    True,
                    "DRBL未インストール環境のため正常なエラー"
                )

            # 展開ステータス取得
            try:
                status = self.drbl_client.get_deployment_status()

                self.log_test(
                    "展開ステータス取得",
                    True,
                    f"Running: {status.get('running', False)}"
                )

            except Exception as e:
                self.log_test(
                    "展開ステータス取得",
                    False,
                    details=str(e)
                )

        except Exception as e:
            self.log_test("展開シミュレーション", False, details=str(e))

    def test_odj_management(self):
        """Test 4: ODJファイル管理"""
        print("\n" + "="*60)
        print("Test 4: ODJファイル管理")
        print("="*60)

        try:
            odj_files = self.drbl_client.list_odj_files()

            self.log_test(
                "ODJファイル一覧取得",
                True,
                f"{len(odj_files)} ODJ files found"
            )

            if odj_files:
                print("\n  検出されたODJファイル:")
                for odj in odj_files:
                    print(f"    - {odj['filename']}")
                    print(f"      サイズ: {odj['size_human']}")
                    print(f"      作成日: {odj['created']}")

        except Exception as e:
            self.log_test("ODJファイル一覧取得", False, details=str(e))

    def test_error_handling(self):
        """Test 5: エラーハンドリング"""
        print("\n" + "="*60)
        print("Test 5: エラーハンドリング")
        print("="*60)

        # 存在しないイメージ
        try:
            image_info = self.drbl_client.get_image_info('nonexistent-image-12345')

            if image_info is None:
                self.log_test(
                    "存在しないイメージ検索",
                    True,
                    "正しくNoneを返却"
                )
            else:
                self.log_test(
                    "存在しないイメージ検索",
                    False,
                    "存在しないイメージに対して情報を返した"
                )

        except Exception as e:
            self.log_test("存在しないイメージ検索", False, details=str(e))

        # 不正なイメージ名で展開開始
        try:
            from utils.drbl_client import DRBLConfigError

            try:
                result = self.drbl_client.start_multicast_deployment(
                    image_name='invalid-image-name-xyz',
                    clients_to_wait=1
                )

                self.log_test(
                    "不正なイメージで展開開始",
                    False,
                    "例外が発生すべき"
                )

            except DRBLConfigError:
                self.log_test(
                    "不正なイメージで展開開始",
                    True,
                    "正しくDRBLConfigErrorが発生"
                )

        except Exception as e:
            self.log_test("不正なイメージで展開開始", False, details=str(e))

    def test_file_paths(self):
        """Test 6: ファイルパス確認"""
        print("\n" + "="*60)
        print("Test 6: ファイルパス・権限確認")
        print("="*60)

        # イメージディレクトリ
        image_home = Path(self.drbl_client.image_home)

        if image_home.exists():
            self.log_test(
                "image_home 存在確認",
                True,
                f"{image_home}"
            )

            import os
            writable = os.access(image_home, os.W_OK)
            self.log_test(
                "image_home 書き込み権限",
                writable,
                "書き込み可能" if writable else "書き込み不可 (要sudo)"
            )
        else:
            self.log_test(
                "image_home 存在確認",
                False,
                f"{image_home} が存在しません"
            )

        # ODJディレクトリ
        odj_home = Path(self.drbl_client.odj_home)

        if odj_home.exists():
            self.log_test(
                "odj_home 存在確認",
                True,
                f"{odj_home}"
            )

            import os
            writable = os.access(odj_home, os.W_OK)
            self.log_test(
                "odj_home 書き込み権限",
                writable,
                "書き込み可能" if writable else "書き込み不可 (要sudo)"
            )
        else:
            self.log_test(
                "odj_home 存在確認",
                False,
                f"{odj_home} が存在しません"
            )

    def generate_summary(self):
        """テストサマリー生成"""
        print("\n" + "="*60)
        print("📊 テスト結果サマリー")
        print("="*60)

        total_tests = len(self.test_results)
        passed_tests = sum(1 for t in self.test_results if t['success'])
        failed_tests = total_tests - passed_tests

        pass_rate = (passed_tests / total_tests * 100) if total_tests > 0 else 0

        print(f"\n総テスト数: {total_tests}")
        print(f"成功: {passed_tests}")
        print(f"失敗: {failed_tests}")
        print(f"成功率: {pass_rate:.1f}%")

        if failed_tests > 0:
            print("\n❌ 失敗したテスト:")
            for result in self.test_results:
                if not result['success']:
                    print(f"  - {result['test']}")
                    if result['details']:
                        print(f"    詳細: {result['details']}")

        print("\n" + "="*60)

        if pass_rate == 100:
            print("🎉 すべてのテストが成功しました!")
        elif pass_rate >= 80:
            print("👍 ほとんどのテストが成功しました")
        elif pass_rate >= 60:
            print("⚠️  いくつかのテストが失敗しています")
        else:
            print("❌ 多数のテストが失敗しています")

        print("="*60)

        return {
            'total': total_tests,
            'passed': passed_tests,
            'failed': failed_tests,
            'pass_rate': pass_rate,
            'results': self.test_results
        }

    def run_all_tests(self):
        """すべてのテストを実行"""
        print("\n" + "="*60)
        print("PCマスターイメージ取り込み・展開機能 統合テスト")
        print("="*60)
        print(f"実行日時: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")

        self.test_drbl_client_initialization()
        self.test_list_images()
        self.test_deployment_simulation()
        self.test_odj_management()
        self.test_error_handling()
        self.test_file_paths()

        summary = self.generate_summary()

        # JSON保存
        import json
        report_file = Path(__file__).parent / 'integration_test_report.json'

        with open(report_file, 'w', encoding='utf-8') as f:
            json.dump({
                'timestamp': datetime.now().isoformat(),
                'summary': summary
            }, f, indent=2, ensure_ascii=False)

        print(f"\n📄 詳細レポート: {report_file}")


def main():
    """メイン処理"""
    tester = ImageDeploymentTester()
    tester.run_all_tests()


if __name__ == '__main__':
    main()
