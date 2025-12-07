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

    # PSWindowsUpdateモジュールのインストール確認
    Write-Log "PSWindowsUpdateモジュールの確認中..."
    if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
        Write-Log "PSWindowsUpdateモジュールをインストール中..."

        # NuGetプロバイダーのインストール
        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -ErrorAction SilentlyContinue

        # PSGalleryを信頼されたリポジトリとして設定
        Set-PSRepository -Name PSGallery -InstallationPolicy Trusted -ErrorAction SilentlyContinue

        # PSWindowsUpdateモジュールをインストール
        Install-Module -Name PSWindowsUpdate -Force -Confirm:$false
        Write-Log "PSWindowsUpdateモジュールのインストールが完了しました"
    }

    Import-Module PSWindowsUpdate
    Write-Log "PSWindowsUpdateモジュールをインポートしました"

    # 更新プログラムの確認とインストールを繰り返す
    $updateCount = 0
    $maxIterations = 10 # 無限ループ防止
    $iteration = 0

    do {
        $iteration++
        Write-Log "----------------------------------------"
        Write-Log "更新確認サイクル ${iteration}/${maxIterations}"
        Write-Log "----------------------------------------"

        # 更新プログラムの確認
        Write-Log "利用可能な更新プログラムを確認中..."
        $updates = Get-WindowsUpdate -MicrosoftUpdate -AcceptAll -IgnoreReboot

        if ($updates.Count -eq 0) {
            Write-Log "新しい更新プログラムはありません"
            break
        }

        Write-Log "見つかった更新プログラム: $($updates.Count)件"
        foreach ($update in $updates) {
            Write-Log "  - $($update.Title)"
        }

        # 更新プログラムのダウンロードとインストール
        Write-Log "更新プログラムをダウンロード・インストール中..."
        $result = Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -IgnoreReboot -Verbose

        $updateCount += $result.Count
        Write-Log "インストール完了: $($result.Count)件"

        # 再起動が必要かチェック
        $rebootRequired = Get-WURebootStatus -Silent
        if ($rebootRequired) {
            Write-Log "再起動が必要です"

            # 再起動後に自動的に続行するためのタスクを作成
            Write-Log "再起動後の自動実行タスクを作成中..."
            $action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -File C:\AutoSetup\scripts\Main-Setup.ps1"
            $trigger = New-ScheduledTaskTrigger -AtLogOn
            $principal = New-ScheduledTaskPrincipal -UserId "owner" -RunLevel Highest
            $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries

            Register-ScheduledTask -TaskName "AutoSetup-Continue" -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force
            Write-Log "自動実行タスクを作成しました"

            Write-Log "5秒後に再起動します..."
            Start-Sleep -Seconds 5
            Restart-Computer -Force
            exit 0
        }

        Write-Log "再起動は不要です。次のサイクルへ進みます..."
        Start-Sleep -Seconds 3

    } while ($iteration -lt $maxIterations)

    Write-Log "----------------------------------------"
    Write-Log "Windows Update完了"
    Write-Log "合計インストール数: ${updateCount}件"
    Write-Log "----------------------------------------"

} catch {
    Write-Log "エラーが発生しました: $($_.Exception.Message)"
    Write-Log "スタックトレース: $($_.ScriptStackTrace)"
    throw
}

Write-Log "Windows Update処理を終了します"
