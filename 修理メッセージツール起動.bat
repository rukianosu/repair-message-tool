@echo off
chcp 65001 > nul
cd /d "%~dp0"

echo ========================================
echo 修理完了連絡メッセージ作成ツール
echo ========================================
echo.
echo ツールを起動しています...
echo ブラウザが自動的に開きます。
echo.
echo 終了するには、このウィンドウを閉じてください。
echo ========================================
echo.

streamlit run RepairStatusNotifier.py

pause
