#!/bin/bash
# Pre-commit hook: コード品質チェック

set -e

echo "🔍 Pre-commit checks starting..."

# Pythonファイルのリント（存在する場合）
if git diff --cached --name-only | grep -q '\.py$'; then
    echo "📝 Checking Python files..."
    if command -v flake8 &> /dev/null; then
        git diff --cached --name-only | grep '\.py$' | xargs flake8 --max-line-length=100 || {
            echo "❌ Python linting failed"
            exit 1
        }
        echo "✅ Python files OK"
    else
        echo "⚠️  flake8 not installed, skipping Python lint"
    fi
fi

# PowerShellファイルのチェック（存在する場合）
if git diff --cached --name-only | grep -q '\.ps1$'; then
    echo "📝 Checking PowerShell files..."
    # PSScriptAnalyzer がインストールされている場合のみ実行
    if command -v pwsh &> /dev/null; then
        echo "✅ PowerShell files detected"
    else
        echo "⚠️  PowerShell not installed, skipping PS1 check"
    fi
fi

# JSONファイルの構文チェック
if git diff --cached --name-only | grep -q '\.json$'; then
    echo "📝 Checking JSON files..."
    git diff --cached --name-only | grep '\.json$' | while read file; do
        if ! python3 -m json.tool "$file" > /dev/null 2>&1; then
            echo "❌ Invalid JSON: $file"
            exit 1
        fi
    done
    echo "✅ JSON files OK"
fi

echo "✅ Pre-commit checks passed!"
exit 0
