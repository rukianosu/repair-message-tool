@echo off
chcp 65001 > nul
cd /d "%~dp0"

echo ========================================
echo 修理完了連絡メッセージ作成ツール
echo ========================================
echo.

REM Pythonがインストールされているか確認
echo [1/3] Pythonの確認中...
python --version >nul 2>&1
if %errorLevel% neq 0 (
    echo [エラー] Pythonがインストールされていません
    echo.
    echo 以下のサイトからPythonをインストールしてください:
    echo https://www.python.org/downloads/
    echo.
    echo インストール時に「Add Python to PATH」にチェックを入れてください
    echo.
    pause
    exit /b 1
)
echo [OK] Python インストール済み
echo.

REM Streamlitがインストールされているか確認
echo [2/3] Streamlitの確認中...
python -c "import streamlit" >nul 2>&1
if %errorLevel% neq 0 (
    echo [エラー] Streamlitがインストールされていません
    echo.
    echo 自動的にインストールを開始します...
    echo.
    pip install streamlit pyperclip
    if %errorLevel% neq 0 (
        echo [エラー] インストールに失敗しました
        echo.
        echo 手動で以下のコマンドを実行してください:
        echo pip install streamlit pyperclip
        echo.
        pause
        exit /b 1
    )
    echo [OK] インストール完了
    echo.
) else (
    echo [OK] Streamlit インストール済み
    echo.
)

REM RepairStatusNotifier.pyが存在するか確認
echo [3/3] プログラムファイルの確認中...
if not exist "RepairStatusNotifier.py" (
    echo [エラー] RepairStatusNotifier.py が見つかりません
    echo.
    echo このバッチファイルと同じフォルダに RepairStatusNotifier.py があることを確認してください
    echo.
    pause
    exit /b 1
)
echo [OK] プログラムファイル確認完了
echo.

echo ========================================
echo ツールを起動しています...
echo ブラウザが自動的に開きます。
echo 終了するには、このウィンドウを閉じてください。
echo ========================================
echo.

streamlit run RepairStatusNotifier.py

pause
