#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Windows 自動セットアップ メインスクリプト

.DESCRIPTION
    このスクリプトは以下の処理を順番に実行します：
    1. Windows Update の完全自動実行
    2. アプリケーションの自動インストール
    3. セットアップ完了通知

.NOTES
    管理者権限が必要です
    unattend.xml の FirstLogonCommands から自動実行されます
#>

# ログファイルパス
$LogFile = "C:\AutoSetup\Logs\Main-Setup.log"
$null = New-Item -ItemType Directory -Force -Path (Split-Path $LogFile)

# セットアップ状態ファイル
$StateFile = "C:\AutoSetup\setup-state.json"

# ログ記録関数
function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] $Message"
    Write-Host $logMessage -ForegroundColor Cyan
    Add-Content -Path $LogFile -Value $logMessage
}

# ビープ音再生関数
function Play-BeepSound {
    param(
        [int]$Frequency = 1000,
        [int]$Duration = 500,
        [int]$Count = 3
    )

    for ($i = 0; $i -lt $Count; $i++) {
        [Console]::Beep($Frequency, $Duration)
        Start-Sleep -Milliseconds 200
    }
}

# デスクトップにメッセージ表示関数
function Show-CompletionMessage {
    $desktopPath = [Environment]::GetFolderPath("Desktop")
    $messageFile = Join-Path $desktopPath "セットアップ完了.txt"

    $message = @"
========================================
Windows 自動セットアップ完了
========================================

セットアップが正常に完了しました。

実行日時: $(Get-Date -Format "yyyy年MM月dd日 HH:mm:ss")

実施内容:
✓ Windows Update
✓ Google Chrome インストール
✓ Adobe Acrobat Reader インストール
✓ PDFファイルをAdobe Readerで開く設定
✓ BitLocker無効化（今後も自動で有効になりません）
✓ パスワード有効期限無効化

ログファイル: C:\AutoSetup\Logs\

このファイルは削除しても問題ありません。

========================================
"@

    $message | Out-File -FilePath $messageFile -Encoding UTF8
    Write-Log "完了メッセージをデスクトップに作成しました: $messageFile"

    # メッセージボックスで表示（オプション）
    Add-Type -AssemblyName PresentationFramework
    [System.Windows.MessageBox]::Show(
        "Windows 自動セットアップが完了しました。`n`nデスクトップの「セットアップ完了.txt」を確認してください。",
        "セットアップ完了",
        [System.Windows.MessageBoxButton]::OK,
        [System.Windows.MessageBoxImage]::Information
    )
}

# セットアップ状態の読み込み
function Get-SetupState {
    if (Test-Path $StateFile) {
        try {
            $state = Get-Content $StateFile -Raw | ConvertFrom-Json
            return $state
        } catch {
            Write-Log "状態ファイルの読み込みに失敗しました。新規作成します。"
        }
    }

    # デフォルト状態
    return [PSCustomObject]@{
        WindowsUpdateCompleted = $false
        AppsInstalled = $false
        BitLockerDisabled = $false
        SetupCompleted = $false
        LastRun = $null
    }
}

# セットアップ状態の保存
function Save-SetupState {
    param($State)
    $State.LastRun = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $State | ConvertTo-Json | Out-File -FilePath $StateFile -Encoding UTF8
}

# ===========================================
# メイン処理開始
# ===========================================

Write-Log "==========================================="
Write-Log "Windows 自動セットアップ メイン処理開始"
Write-Log "==========================================="

try {
    # セットアップ状態の確認
    $state = Get-SetupState

    # すでに完了している場合はスキップ
    if ($state.SetupCompleted) {
        Write-Log "セットアップは既に完了しています。"
        Write-Log "再実行する場合は、$StateFile を削除してください。"

        # 再起動後の自動実行タスクを削除
        $taskName = "AutoSetup-Continue"
        if (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue) {
            Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
            Write-Log "自動実行タスク「$taskName」を削除しました"
        }

        exit 0
    }

    # ===========================================
    # ステップ1: Windows Update
    # ===========================================
    if (-not $state.WindowsUpdateCompleted) {
        Write-Log "==========================================="
        Write-Log "ステップ 1/3: Windows Update"
        Write-Log "==========================================="

        $updateScript = "C:\AutoSetup\scripts\01-WindowsUpdate.ps1"
        if (Test-Path $updateScript) {
            & $updateScript

            # Windows Updateで再起動が発生した場合、ここには到達しない
            $state.WindowsUpdateCompleted = $true
            Save-SetupState -State $state
            Write-Log "Windows Update が完了しました"
        } else {
            Write-Log "エラー: $updateScript が見つかりません"
        }
    } else {
        Write-Log "Windows Update は既に完了しています（スキップ）"
    }

    # ===========================================
    # ステップ2: アプリケーションインストール
    # ===========================================
    if (-not $state.AppsInstalled) {
        Write-Log "==========================================="
        Write-Log "ステップ 2/3: アプリケーションインストール"
        Write-Log "==========================================="

        $appScript = "C:\AutoSetup\scripts\02-InstallApps.ps1"
        if (Test-Path $appScript) {
            & $appScript

            $state.AppsInstalled = $true
            Save-SetupState -State $state
            Write-Log "アプリケーションのインストールが完了しました"
        } else {
            Write-Log "エラー: $appScript が見つかりません"
        }
    } else {
        Write-Log "アプリケーションは既にインストール済みです（スキップ）"
    }

    # ===========================================
    # ステップ3: BitLocker無効化
    # ===========================================
    if (-not $state.BitLockerDisabled) {
        Write-Log "==========================================="
        Write-Log "ステップ 3/3: BitLocker無効化"
        Write-Log "==========================================="

        $bitlockerScript = "C:\AutoSetup\scripts\03-DisableBitLocker.ps1"
        if (Test-Path $bitlockerScript) {
            & $bitlockerScript

            $state.BitLockerDisabled = $true
            Save-SetupState -State $state
            Write-Log "BitLocker無効化が完了しました"
        } else {
            Write-Log "エラー: $bitlockerScript が見つかりません"
        }
    } else {
        Write-Log "BitLockerは既に無効化されています（スキップ）"
    }

    # ===========================================
    # パスワード有効期限の無効化
    # ===========================================
    Write-Log "----------------------------------------"
    Write-Log "パスワード有効期限の無効化"
    Write-Log "----------------------------------------"

    try {
        # ユーザー「owner」のパスワード有効期限を無効化
        Write-Log "ユーザー「owner」のパスワード有効期限を無効化中..."
        $result = wmic useraccount where "name='owner'" set PasswordExpires=false 2>&1

        # 全アカウントのパスワード有効期限を無制限に設定
        Write-Log "全アカウントのパスワード有効期限を無制限に設定中..."
        net accounts /maxpwage:unlimited | Out-Null

        Write-Log "✓ パスワード有効期限を無効化しました"
    } catch {
        Write-Log "警告: パスワード有効期限の無効化に失敗しました: $($_.Exception.Message)"
    }

    # ===========================================
    # ステップ4: セットアップ完了処理
    # ===========================================
    Write-Log "==========================================="
    Write-Log "セットアップ完了処理"
    Write-Log "==========================================="

    # 完了状態を保存
    $state.SetupCompleted = $true
    Save-SetupState -State $state

    # 再起動後の自動実行タスクを削除
    $taskName = "AutoSetup-Continue"
    if (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue) {
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
        Write-Log "自動実行タスク「$taskName」を削除しました"
    }

    # ビープ音で完了通知
    Write-Log "ビープ音で完了を通知します..."
    Play-BeepSound -Frequency 1000 -Duration 300 -Count 3

    # デスクトップにメッセージ表示
    Write-Log "デスクトップに完了メッセージを表示します..."
    Show-CompletionMessage

    Write-Log "==========================================="
    Write-Log "すべてのセットアップが完了しました！"
    Write-Log "==========================================="

} catch {
    Write-Log "エラーが発生しました: $($_.Exception.Message)"
    Write-Log "スタックトレース: $($_.ScriptStackTrace)"

    # エラー通知
    Add-Type -AssemblyName PresentationFramework
    [System.Windows.MessageBox]::Show(
        "セットアップ中にエラーが発生しました。`n`nログファイル: $LogFile",
        "セットアップエラー",
        [System.Windows.MessageBoxButton]::OK,
        [System.Windows.MessageBoxImage]::Error
    )

    throw
}

Write-Log "メインスクリプトを終了します"
