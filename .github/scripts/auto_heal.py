#!/usr/bin/env python3
"""
自動エラー検知・修復システム

このスクリプトは、プロジェクト内のエラーを自動検知し、
15回までのリトライループで自動修復を試みます。
"""

import argparse
import json
import subprocess
import sys
import os
import re
from typing import List, Dict, Tuple
from datetime import datetime
from pathlib import Path


class ErrorDetector:
    """エラー検知クラス"""

    def __init__(self):
        self.errors = []

    def detect_syntax_errors(self) -> List[Dict]:
        """Python構文エラーを検知"""
        errors = []
        print("🔍 Python構文エラーを検知中...")

        try:
            result = subprocess.run(
                ["flake8", "flask-app/", "--config=flask-app/.flake8", "--select=E9,F63,F7,F82", "--format=json"],
                capture_output=True,
                text=True
            )

            if result.stdout:
                flake_errors = json.loads(result.stdout) if result.stdout.strip() else []
                for err in flake_errors:
                    errors.append({
                        'type': 'syntax_error',
                        'file': err.get('filename', ''),
                        'line': err.get('line_number', 0),
                        'column': err.get('column_number', 0),
                        'code': err.get('code', ''),
                        'message': err.get('text', ''),
                        'severity': 'critical'
                    })
        except Exception as e:
            print(f"⚠️ 構文エラー検知中にエラー: {e}")

        print(f"  → {len(errors)}個の構文エラーを検出")
        return errors

    def detect_test_failures(self) -> List[Dict]:
        """テスト失敗を検知"""
        errors = []
        print("🔍 テスト失敗を検知中...")

        try:
            # flask-appディレクトリからpytestを実行（pytest.iniを正しく読み込むため）
            result = subprocess.run(
                ["pytest", "tests/", "--tb=short", "--maxfail=10", "-v"],
                capture_output=True,
                text=True,
                cwd="flask-app"
            )

            if result.returncode != 0:
                # テスト失敗をパース
                lines = result.stdout.split('\n')
                for line in lines:
                    if 'FAILED' in line:
                        match = re.search(r'FAILED (.*)::(.*) - (.*)', line)
                        if match:
                            errors.append({
                                'type': 'test_failure',
                                'file': match.group(1),
                                'test': match.group(2),
                                'message': match.group(3),
                                'severity': 'high'
                            })
        except Exception as e:
            print(f"⚠️ テスト失敗検知中にエラー: {e}")

        print(f"  → {len(errors)}個のテスト失敗を検出")
        return errors

    def detect_import_errors(self) -> List[Dict]:
        """Import エラーを検知"""
        errors = []
        print("🔍 Importエラーを検知中...")

        try:
            # pyflakesでimportエラーを検知
            # __init__.pyは除外（Blueprintルート登録に必要なインポートを含むため）
            result = subprocess.run(
                ["python", "-m", "pyflakes",
                 "flask-app/app.py", "flask-app/config.py"],
                capture_output=True,
                text=True
            )

            if result.stdout:
                for line in result.stdout.split('\n'):
                    if 'imported but unused' in line or 'undefined name' in line:
                        # __init__.pyファイルは除外
                        if '__init__.py' in line:
                            continue
                        match = re.match(r"^(.+?):(\d+):(.+)$", line)
                        if match:
                            errors.append({
                                'type': 'import_error',
                                'file': match.group(1),
                                'line': int(match.group(2)),
                                'message': match.group(3).strip(),
                                'severity': 'medium'
                            })
        except Exception as e:
            print(f"⚠️ Importエラー検知中にエラー: {e}")

        print(f"  → {len(errors)}個のImportエラーを検出")
        return errors

    def detect_code_quality_issues(self) -> List[Dict]:
        """コード品質問題を検知"""
        errors = []
        print("🔍 コード品質問題を検知中...")

        try:
            result = subprocess.run(
                ["flake8", "flask-app/", "--config=flask-app/.flake8", "--count", "--statistics"],
                capture_output=True,
                text=True
            )

            if result.returncode != 0:
                # 統計情報から重大な問題のみ抽出
                for line in result.stdout.split('\n'):
                    if any(code in line for code in ['E501', 'W503', 'F401']):
                        errors.append({
                            'type': 'code_quality',
                            'message': line.strip(),
                            'severity': 'low'
                        })
        except Exception as e:
            print(f"⚠️ コード品質検知中にエラー: {e}")

        print(f"  → {len(errors)}個のコード品質問題を検出")
        return errors

    def detect_all(self) -> List[Dict]:
        """全種類のエラーを検知"""
        print("\n" + "="*60)
        print("🔍 全エラー検知を開始")
        print("="*60 + "\n")

        all_errors = []
        all_errors.extend(self.detect_syntax_errors())
        all_errors.extend(self.detect_test_failures())
        all_errors.extend(self.detect_import_errors())
        all_errors.extend(self.detect_code_quality_issues())

        # 重複排除
        unique_errors = []
        seen = set()
        for err in all_errors:
            key = f"{err.get('file', '')}:{err.get('line', 0)}:{err.get('message', '')}"
            if key not in seen:
                seen.add(key)
                unique_errors.append(err)

        print(f"\n✅ 合計 {len(unique_errors)}個のユニークなエラーを検出\n")
        return unique_errors


class ErrorHealer:
    """エラー自動修復クラス"""

    def __init__(self):
        self.fixes_applied = []

    def fix_unused_imports(self, error: Dict) -> bool:
        """未使用インポートを削除"""
        if 'imported but unused' not in error.get('message', ''):
            return False

        try:
            file_path = error['file']
            line_num = error['line']

            # __init__.pyファイルのインポートは削除しない（Blueprintルート登録に必要）
            if file_path.endswith('__init__.py'):
                print(f"  ⚠️ スキップ: __init__.pyのインポートは削除しません（ルート登録に必要）")
                return False

            # ファイルを読み込み
            with open(file_path, 'r', encoding='utf-8') as f:
                lines = f.readlines()

            # 該当行を確認
            if 0 < line_num <= len(lines):
                target_line = lines[line_num - 1]

                # noqaコメントがある行は削除しない
                if '# noqa' in target_line or '#noqa' in target_line:
                    print(f"  ⚠️ スキップ: noqaコメントがある行は削除しません")
                    return False

                # 該当行を削除
                removed_line = target_line.strip()
                lines.pop(line_num - 1)

                # ファイルに書き戻し
                with open(file_path, 'w', encoding='utf-8') as f:
                    f.writelines(lines)

                self.fixes_applied.append({
                    'file': file_path,
                    'line': line_num,
                    'fix_type': 'remove_unused_import',
                    'removed': removed_line
                })

                print(f"  ✅ 未使用インポートを削除: {file_path}:{line_num}")
                return True

        except Exception as e:
            print(f"  ❌ 修復失敗: {e}")
            return False

        return False

    def fix_indentation_errors(self, error: Dict) -> bool:
        """インデントエラーを修正"""
        if 'indentation' not in error.get('message', '').lower():
            return False

        try:
            file_path = error['file']

            # autopep8で自動修正
            result = subprocess.run(
                ["autopep8", "--in-place", "--select=E1", file_path],
                capture_output=True,
                text=True
            )

            if result.returncode == 0:
                self.fixes_applied.append({
                    'file': file_path,
                    'fix_type': 'fix_indentation'
                })
                print(f"  ✅ インデントエラーを修正: {file_path}")
                return True

        except Exception as e:
            print(f"  ❌ 修復失敗: {e}")

        return False

    def fix_missing_imports(self, error: Dict) -> bool:
        """不足しているインポートを追加"""
        if 'undefined name' not in error.get('message', ''):
            return False

        try:
            # 未定義変数名を抽出
            match = re.search(r"undefined name '(\w+)'", error['message'])
            if not match:
                return False

            undefined_name = match.group(1)
            file_path = error['file']

            # 一般的なインポートマッピング
            import_mappings = {
                'Flask': 'from flask import Flask',
                'request': 'from flask import request',
                'jsonify': 'from flask import jsonify',
                'Blueprint': 'from flask import Blueprint',
                'db': 'from models import db',
                'PCMaster': 'from models import PCMaster',
                'SetupLog': 'from models import SetupLog',
                'datetime': 'from datetime import datetime',
                'Optional': 'from typing import Optional',
                'List': 'from typing import List',
                'Dict': 'from typing import Dict',
            }

            if undefined_name in import_mappings:
                import_line = import_mappings[undefined_name] + '\n'

                # ファイルに追加
                with open(file_path, 'r', encoding='utf-8') as f:
                    lines = f.readlines()

                # インポートセクションを探して追加
                insert_pos = 0
                for i, line in enumerate(lines):
                    if line.strip().startswith('import ') or line.strip().startswith('from '):
                        insert_pos = i + 1

                lines.insert(insert_pos, import_line)

                with open(file_path, 'w', encoding='utf-8') as f:
                    f.writelines(lines)

                self.fixes_applied.append({
                    'file': file_path,
                    'fix_type': 'add_missing_import',
                    'added': import_line.strip()
                })

                print(f"  ✅ 不足インポートを追加: {undefined_name} → {file_path}")
                return True

        except Exception as e:
            print(f"  ❌ 修復失敗: {e}")

        return False

    def run_auto_format(self) -> int:
        """自動フォーマット実行"""
        fixed_count = 0
        print("\n🎨 自動フォーマット実行中...")

        try:
            # blackでフォーマット
            result = subprocess.run(
                ["black", "flask-app/", "--quiet"],
                capture_output=True,
                text=True
            )

            if result.returncode == 0:
                # 変更されたファイル数をカウント
                result_check = subprocess.run(
                    ["git", "diff", "--name-only"],
                    capture_output=True,
                    text=True
                )
                changed_files = [f for f in result_check.stdout.split('\n') if f]
                fixed_count = len(changed_files)

                if fixed_count > 0:
                    self.fixes_applied.append({
                        'fix_type': 'auto_format',
                        'files': changed_files
                    })
                    print(f"  ✅ {fixed_count}個のファイルをフォーマット")

        except Exception as e:
            print(f"  ⚠️ フォーマット中にエラー: {e}")

        return fixed_count

    def heal(self, errors: List[Dict]) -> Tuple[int, List[Dict]]:
        """エラーを自動修復"""
        print("\n" + "="*60)
        print("🔧 自動修復を開始")
        print("="*60 + "\n")

        fixed_count = 0
        remaining_errors = []

        for idx, error in enumerate(errors, 1):
            print(f"\n[{idx}/{len(errors)}] 修復試行: {error.get('type', 'unknown')}")
            print(f"  ファイル: {error.get('file', 'N/A')}")
            print(f"  メッセージ: {error.get('message', 'N/A')}")

            # 修復試行
            fixed = False

            if error['type'] == 'import_error':
                fixed = self.fix_unused_imports(error) or self.fix_missing_imports(error)
            elif error['type'] == 'syntax_error':
                fixed = self.fix_indentation_errors(error)

            if fixed:
                fixed_count += 1
            else:
                remaining_errors.append(error)
                print(f"  ⚠️ 自動修復できませんでした")

        # 自動フォーマット実行
        format_fixed = self.run_auto_format()
        if format_fixed > 0:
            fixed_count += format_fixed

        print(f"\n✅ 修復完了: {fixed_count}個のエラーを修正")
        print(f"⚠️ 残存エラー: {len(remaining_errors)}個\n")

        return fixed_count, remaining_errors


class AutoHealSystem:
    """自動修復システムのメインクラス"""

    def __init__(self, max_iterations: int = 15):
        self.max_iterations = max_iterations
        self.detector = ErrorDetector()
        self.healer = ErrorHealer()
        self.iteration_history = []

    def run_iteration(self, iteration: int) -> Dict:
        """1回の検知・修復サイクルを実行"""
        print("\n" + "="*60)
        print(f"🔄 反復 {iteration}/{self.max_iterations}")
        print("="*60)

        # エラー検知
        errors = self.detector.detect_all()

        if not errors:
            print("\n🎉 エラーは検出されませんでした！")
            return {
                'iteration': iteration,
                'errors_detected': 0,
                'errors_fixed': 0,
                'errors_remaining': 0,
                'status': 'success'
            }

        # エラー修復
        fixed_count, remaining_errors = self.healer.heal(errors)

        result = {
            'iteration': iteration,
            'errors_detected': len(errors),
            'errors_fixed': fixed_count,
            'errors_remaining': len(remaining_errors),
            'remaining_error_details': remaining_errors[:10],  # 最初の10個のみ
            'status': 'fixed' if fixed_count > 0 else 'no_fix'
        }

        self.iteration_history.append(result)
        return result

    def run(self) -> Dict:
        """最大15回のループで自動修復を実行"""
        print("\n" + "="*70)
        print("🚀 自動エラー検知・修復システム起動")
        print("="*70)
        print(f"最大反復回数: {self.max_iterations}")
        print(f"開始時刻: {datetime.now().isoformat()}")
        print("="*70 + "\n")

        total_errors = 0
        total_fixed = 0
        final_remaining = 0

        for i in range(1, self.max_iterations + 1):
            result = self.run_iteration(i)

            total_errors += result['errors_detected']
            total_fixed += result['errors_fixed']
            final_remaining = result['errors_remaining']

            # エラーがなくなったら終了
            if result['errors_remaining'] == 0 and result['errors_detected'] > 0:
                print("\n✅ 全てのエラーが修復されました！")
                break

            # 修復が進まなくなったら終了
            if result['errors_detected'] > 0 and result['errors_fixed'] == 0:
                if i > 1:  # 少なくとも2回は試行
                    print("\n⚠️ これ以上の自動修復は不可能です")
                    break

            # 最後の反復でエラーが残っている場合
            if i == self.max_iterations and result['errors_remaining'] > 0:
                print(f"\n⚠️ 最大反復回数({self.max_iterations})に達しました")
                print(f"   残存エラー: {result['errors_remaining']}個")

        # サマリー作成
        summary = {
            'total_errors': total_errors,
            'fixed_errors': total_fixed,
            'remaining_errors': final_remaining,
            'iterations': len(self.iteration_history),
            'max_iterations': self.max_iterations,
            'start_time': datetime.now().isoformat(),
            'fixes_applied': self.healer.fixes_applied,
            'iteration_history': self.iteration_history,
            'remaining_error_details': self.iteration_history[-1].get('remaining_error_details', []) if self.iteration_history else []
        }

        # GitHub Actions出力に設定
        self._set_github_output(summary)

        # サマリーをJSONファイルに保存
        with open('auto_heal_summary.json', 'w', encoding='utf-8') as f:
            json.dump(summary, f, indent=2, ensure_ascii=False)

        # 詳細ログを保存
        self._save_detailed_log(summary)

        return summary

    def _set_github_output(self, summary: Dict):
        """GitHub Actions出力を設定"""
        try:
            github_output = os.getenv('GITHUB_OUTPUT')
            if github_output:
                with open(github_output, 'a') as f:
                    f.write(f"has_fixes={'true' if summary['fixed_errors'] > 0 else 'false'}\n")
                    f.write(f"fixed_count={summary['fixed_errors']}\n")
                    f.write(f"total_errors={summary['total_errors']}\n")
                    f.write(f"remaining_errors={summary['remaining_errors']}\n")
                    f.write(f"iterations={summary['iterations']}\n")

                    # 修復サマリー
                    fix_summary = "\n".join([
                        f"- {fix['fix_type']}: {fix.get('file', 'multiple files')}"
                        for fix in summary['fixes_applied'][:10]
                    ])
                    f.write(f"fix_summary<<EOF\n{fix_summary}\nEOF\n")

        except Exception as e:
            print(f"⚠️ GitHub出力設定エラー: {e}")

    def _save_detailed_log(self, summary: Dict):
        """詳細ログを保存"""
        try:
            with open('auto_heal_detailed.log', 'w', encoding='utf-8') as f:
                f.write("="*70 + "\n")
                f.write("自動エラー検知・修復システム 詳細ログ\n")
                f.write("="*70 + "\n\n")

                f.write(f"実行日時: {summary['start_time']}\n")
                f.write(f"最大反復回数: {summary['max_iterations']}\n")
                f.write(f"実際の反復回数: {summary['iterations']}\n\n")

                f.write("## 統計\n\n")
                f.write(f"- 総エラー数: {summary['total_errors']}\n")
                f.write(f"- 修復済み: {summary['fixed_errors']}\n")
                f.write(f"- 残存エラー: {summary['remaining_errors']}\n\n")

                f.write("## 反復履歴\n\n")
                for hist in summary['iteration_history']:
                    f.write(f"反復 {hist['iteration']}:\n")
                    f.write(f"  検出: {hist['errors_detected']}, ")
                    f.write(f"修復: {hist['errors_fixed']}, ")
                    f.write(f"残存: {hist['errors_remaining']}\n")

                f.write("\n## 適用された修復\n\n")
                for fix in summary['fixes_applied']:
                    f.write(f"- {fix['fix_type']}: {fix.get('file', 'N/A')}\n")

                if summary['remaining_errors'] > 0:
                    f.write("\n## 未修復エラー\n\n")
                    for err in summary['remaining_error_details']:
                        f.write(f"- {err['type']}: {err.get('file', 'N/A')} - {err.get('message', 'N/A')}\n")

        except Exception as e:
            print(f"⚠️ ログ保存エラー: {e}")


def main():
    """メイン関数"""
    parser = argparse.ArgumentParser(description='自動エラー検知・修復システム')
    parser.add_argument('--max-iterations', type=int, default=15, help='最大反復回数')
    parser.add_argument('--github-token', type=str, help='GitHub Token')
    parser.add_argument('--repo', type=str, help='リポジトリ名（owner/repo）')
    parser.add_argument('--run-id', type=str, help='ワークフロー実行ID')
    parser.add_argument('--actor', type=str, help='実行者')

    args = parser.parse_args()

    # 自動修復システムを実行
    system = AutoHealSystem(max_iterations=args.max_iterations)
    summary = system.run()

    # 結果表示
    print("\n" + "="*70)
    print("📊 最終結果")
    print("="*70)
    print(f"総エラー数: {summary['total_errors']}")
    print(f"修復済み: {summary['fixed_errors']}")
    print(f"残存エラー: {summary['remaining_errors']}")
    print(f"反復回数: {summary['iterations']}/{summary['max_iterations']}")
    print("="*70 + "\n")

    # 修復があった場合は終了コード0、エラーが残っている場合は1
    if summary['remaining_errors'] > 0:
        print("⚠️ 一部のエラーが修復できませんでした")
        sys.exit(1)
    else:
        print("✅ 全てのエラーが修復されました！")
        sys.exit(0)


if __name__ == '__main__':
    main()
