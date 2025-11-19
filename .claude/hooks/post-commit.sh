#!/bin/bash
# Post-commit hook: コミット後の処理

set -e

echo "📊 Post-commit processing..."

# コミットメッセージを取得
COMMIT_MSG=$(git log -1 --pretty=%B)

# 統計情報を表示
FILES_CHANGED=$(git diff --name-only HEAD~1 HEAD | wc -l)
LINES_ADDED=$(git diff --stat HEAD~1 HEAD | tail -1 | grep -oP '\d+(?= insertion)' || echo "0")
LINES_DELETED=$(git diff --stat HEAD~1 HEAD | tail -1 | grep -oP '\d+(?= deletion)' || echo "0")

echo "📈 Commit statistics:"
echo "   Files changed: $FILES_CHANGED"
echo "   Lines added: $LINES_ADDED"
echo "   Lines deleted: $LINES_DELETED"

# 変更されたファイルのタイプを検出
if git diff --name-only HEAD~1 HEAD | grep -q '\.py$'; then
    echo "🐍 Python files modified"
fi

if git diff --name-only HEAD~1 HEAD | grep -q '\.ps1$'; then
    echo "💠 PowerShell files modified"
fi

if git diff --name-only HEAD~1 HEAD | grep -q '\.md$'; then
    echo "📝 Documentation files modified"
fi

echo "✅ Post-commit processing complete!"
exit 0
