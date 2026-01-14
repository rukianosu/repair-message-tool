@echo off
cd /d "%~dp0"

echo 修理メッセージツールを起動中...
echo ブラウザが自動的に開きます。
echo.
echo 終了する場合は、このウィンドウを閉じてください。
echo.

streamlit run RepairStatusNotifier.py

if %errorLevel% neq 0 (
    echo.
    echo エラーが発生しました。
    pause
)
