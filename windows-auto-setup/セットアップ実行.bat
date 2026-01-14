@echo off
chcp 65001 > nul
REM ====================================================================
REM Windows 自動セットアップ 実行バッチファイル
REM このファイルを右クリック → 「管理者として実行」してください
REM ====================================================================

echo.
echo ========================================
echo Windows 自動セットアップ
echo ========================================
echo.

REM 管理者権限チェック
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [エラー] 管理者権限が必要です
    echo.
    echo 右クリック → 「管理者として実行」で起動してください
    echo.
    pause
    exit /b 1
)

echo [OK] 管理者権限確認
echo.

REM 現在のバッチファイルのディレクトリを取得
set "SCRIPT_DIR=%~dp0"
echo スクリプトの場所: %SCRIPT_DIR%
echo.

REM コピー先の確認
echo ========================================
echo ステップ1: スクリプトをPCにコピー
echo ========================================
echo.

REM 既存のフォルダがあれば削除
if exist "C:\AutoSetup" (
    echo 既存のフォルダを削除中...
    rmdir /s /q "C:\AutoSetup"
)

REM スクリプトをコピー
echo スクリプトをコピー中...
xcopy /E /I /Y "%SCRIPT_DIR%scripts" "C:\AutoSetup\scripts" > nul
if %errorLevel% neq 0 (
    echo [エラー] スクリプトのコピーに失敗しました
    echo.
    pause
    exit /b 1
)

echo [OK] スクリプトのコピー完了
echo.

REM PowerShell実行ポリシーを変更
echo ========================================
echo ステップ2: PowerShell実行ポリシーを変更
echo ========================================
echo.

powershell.exe -NoProfile -Command "Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope LocalMachine -Force"
if %errorLevel% neq 0 (
    echo [エラー] 実行ポリシーの変更に失敗しました
    echo.
    pause
    exit /b 1
)

echo [OK] 実行ポリシー変更完了
echo.

REM メインスクリプトを実行
echo ========================================
echo ステップ3: 自動セットアップを開始
echo ========================================
echo.
echo これから自動セットアップが開始されます。
echo 処理には1〜3時間かかります。
echo.
echo 途中で再起動する場合があります。
echo 再起動後は自動的に続行されます。
echo.
pause

REM PowerShellスクリプトを実行
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\AutoSetup\scripts\Main-Setup.ps1"

echo.
echo ========================================
echo 処理が完了しました
echo ========================================
echo.
pause
