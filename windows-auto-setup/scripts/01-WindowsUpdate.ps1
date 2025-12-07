#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Windows Update 完全自動実行スクリプト

.DESCRIPTION
    このスクリプトは以下を自動実行します：
    1. Windows Updateの確認
    2. 利用可能な更新プログラムのダウンロードとインストール
    3. 必要に応じて自動再起動
    4. 更新がなくなるまで繰り返し実行

.NOTES
    管理者権限が必要です
#>

# ログファイルパス
$LogFile = "C:\AutoSetup\Logs\WindowsUpdate.log"
$null = New-Item -ItemType Directory -Force -Path (Split-Path $LogFile)

# ログ記録関数
function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] $Message"
    Write-Host $logMessage
    Add-Content -Path $LogFile -Value $logMessage
}

Write-Log "========================================="
Write-Log "Windows Update 自動実行を開始します"
Write-Log "========================================="

try {
    # Windows Updateサービスの状態を確認
    Write-Log "Windows Updateサービスの状態を確認中..."
    $wuService = Get-Service -Name wuauserv
    if ($wuService.Status -ne 'Running') {
        Write-Log "Windows Updateサービスを開始します..."
        Start-Service -Name wuauserv
        Start-Sleep -Seconds 5
    }

    # Windows Update COM オブジェクトを使用した更新
    Write-Log "Windows Update セッションを作成中..."

    $updateSession = New-Object -ComObject Microsoft.Update.Session
    $updateSearcher = $updateSession.CreateUpdateSearcher()

    Write-Log "利用可能な更新プログラムを検索中..."
    Write-Log "※この処理には数分かかる場合があります"

    $searchResult = $updateSearcher.Search("IsInstalled=0 and Type='Software'")

    if ($searchResult.Updates.Count -eq 0) {
        Write-Log "新しい更新プログラムはありません"
        Write-Log "Windows Update完了"
        exit 0
    }

    Write-Log "見つかった更新プログラム: $($searchResult.Updates.Count)件"

    # 更新プログラムのタイトルを表示
    foreach ($update in $searchResult.Updates) {
        Write-Log "  - $($update.Title)"
    }

    # 更新プログラムのダウンロード
    Write-Log "----------------------------------------"
    Write-Log "更新プログラムをダウンロード中..."
    Write-Log "----------------------------------------"

    $updatesToDownload = New-Object -ComObject Microsoft.Update.UpdateColl
    foreach ($update in $searchResult.Updates) {
        $updatesToDownload.Add($update) | Out-Null
    }

    $downloader = $updateSession.CreateUpdateDownloader()
    $downloader.Updates = $updatesToDownload
    $downloadResult = $downloader.Download()

    Write-Log "ダウンロード完了"

    # 更新プログラムのインストール
    Write-Log "----------------------------------------"
    Write-Log "更新プログラムをインストール中..."
    Write-Log "※この処理には時間がかかる場合があります"
    Write-Log "----------------------------------------"

    $updatesToInstall = New-Object -ComObject Microsoft.Update.UpdateColl
    foreach ($update in $searchResult.Updates) {
        if ($update.IsDownloaded) {
            $updatesToInstall.Add($update) | Out-Null
        }
    }

    if ($updatesToInstall.Count -eq 0) {
        Write-Log "インストール可能な更新プログラムがありません"
        exit 0
    }

    $installer = $updateSession.CreateUpdateInstaller()
    $installer.Updates = $updatesToInstall
    $installResult = $installer.Install()

    Write-Log "インストール完了: $($updatesToInstall.Count)件"
    Write-Log "インストール結果コード: $($installResult.ResultCode)"

    # 再起動が必要かチェック
    if ($installResult.RebootRequired) {
        Write-Log "----------------------------------------"
        Write-Log "再起動が必要です"
        Write-Log "----------------------------------------"

        # 再起動後に自動的に続行するためのタスクを作成
        Write-Log "再起動後の自動実行タスクを作成中..."
        $action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -File C:\AutoSetup\scripts\Main-Setup.ps1"
        $trigger = New-ScheduledTaskTrigger -AtLogOn
        $principal = New-ScheduledTaskPrincipal -UserId "owner" -RunLevel Highest
        $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries

        Register-ScheduledTask -TaskName "AutoSetup-Continue" -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force
        Write-Log "自動実行タスクを作成しました"

        Write-Log "10秒後に再起動します..."
        Start-Sleep -Seconds 10
        Restart-Computer -Force
        exit 0
    } else {
        Write-Log "再起動は不要です"
        Write-Log "----------------------------------------"
        Write-Log "Windows Update完了"
        Write-Log "----------------------------------------"
    }

} catch {
    Write-Log "エラーが発生しました: $($_.Exception.Message)"
    Write-Log "スタックトレース: $($_.ScriptStackTrace)"
    Write-Log ""
    Write-Log "========================================="
    Write-Log "Windows Updateで問題が発生しました"
    Write-Log "手動でWindows Updateを実行してください"
    Write-Log "========================================="
    Write-Log ""
    Write-Log "手動実行方法:"
    Write-Log "1. スタートメニュー → 設定"
    Write-Log "2. Windows Update"
    Write-Log "3. 「更新プログラムのチェック」をクリック"
    Write-Log "4. すべて適用されるまで繰り返し"

    # エラーが発生してもスクリプトは続行（次のステップに進む）
    exit 0
}

Write-Log "Windows Update処理を終了します"
