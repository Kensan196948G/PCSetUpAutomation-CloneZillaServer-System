@echo off
REM ポストデプロイスクリプト例：コンピューター名の自動設定
REM MACアドレスの下6桁を使用してPC名を生成
REM 使用方法: イメージに含めてWindows起動時に自動実行

echo ==========================================
echo PC名自動設定スクリプト
echo ==========================================
echo.

REM 管理者権限チェック
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo エラー: このスクリプトは管理者権限で実行してください
    pause
    exit /b 1
)

REM MACアドレス取得
echo MACアドレスを取得中...
for /f "skip=1 tokens=1" %%a in ('wmic nic where "NetEnabled=true" get MACAddress') do (
    set MAC=%%a
    goto :got_mac
)
:got_mac

if "%MAC%"=="" (
    echo エラー: MACアドレスの取得に失敗しました
    pause
    exit /b 1
)

REM MACアドレスの下6桁を取得（ハイフンを除去）
set MAC_CLEAN=%MAC::=%
set MAC_SHORT=%MAC_CLEAN:~-6%

REM 会社プレフィックス設定（環境に応じて変更）
set PREFIX=PC

REM 新しいPC名を生成
set NEW_NAME=%PREFIX%-%MAC_SHORT%

echo.
echo 現在のPC名: %COMPUTERNAME%
echo 新しいPC名: %NEW_NAME%
echo.

REM PC名変更
echo PC名を変更しています...
wmic computersystem where name="%COMPUTERNAME%" call rename name="%NEW_NAME%"

if %errorLevel% equ 0 (
    echo.
    echo PC名の変更に成功しました
    echo 30秒後に再起動します...
    echo.
    
    REM このスクリプトを次回起動時に実行しないようにする
    REM （スタートアップから削除など、環境に応じて実装）
    
    shutdown /r /t 30 /c "PC名変更のため再起動します"
) else (
    echo.
    echo エラー: PC名の変更に失敗しました
    pause
    exit /b 1
)

exit /b 0
