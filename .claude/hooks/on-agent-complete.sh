#!/bin/bash
# On-agent-complete hook: エージェント完了時の処理

set -e

AGENT_NAME="${1:-unknown}"
AGENT_STATUS="${2:-unknown}"

echo "🤖 Agent completed: $AGENT_NAME"
echo "📊 Status: $AGENT_STATUS"

# エージェント完了ログを記録
LOG_DIR=".claude/logs"
mkdir -p "$LOG_DIR"

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
echo "[$TIMESTAMP] Agent: $AGENT_NAME, Status: $AGENT_STATUS" >> "$LOG_DIR/agent-completion.log"

# エージェントタイプ別の後処理
case "$AGENT_NAME" in
    "flask-backend-dev"|"api-developer")
        echo "🐍 Backend development completed"
        # 必要に応じてテスト実行等
        ;;
    "powershell-scripter"|"windows-automation")
        echo "💠 PowerShell script development completed"
        ;;
    "test-engineer"|"integration-tester")
        echo "🧪 Testing completed"
        # テスト結果のサマリを表示
        ;;
    "database-architect")
        echo "🗄️  Database work completed"
        ;;
    "documentation-writer")
        echo "📝 Documentation updated"
        ;;
    *)
        echo "✅ Agent work completed"
        ;;
esac

exit 0
