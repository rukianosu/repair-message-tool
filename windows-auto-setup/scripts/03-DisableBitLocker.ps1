#Requires -RunAsAdministrator

<#
.SYNOPSIS
    BitLocker無効化スクリプト

.DESCRIPTION
    このスクリプトは以下を実行します：
    1. BitLockerの無効化（既に有効な場合）
    2. BitLockerの自動暗号化を無効化
    3. 将来の大型アップデートでBitLockerが自動で有効にならないよう設定

.NOTES
    管理者権限が必要です
#>

# ログファイルパス
$LogFile = "C:\AutoSetup\Logs\BitLocker.log"
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
Write-Log "BitLocker無効化処理を開始します"
Write-Log "========================================="

try {
    # ========================================
    # 1. 現在のBitLocker状態を確認
    # ========================================
    Write-Log "BitLockerの状態を確認中..."

    $volumes = Get-BitLockerVolume -ErrorAction SilentlyContinue

    if ($volumes) {
        foreach ($volume in $volumes) {
            Write-Log "ドライブ $($volume.MountPoint): $($volume.ProtectionStatus)"

            if ($volume.ProtectionStatus -eq "On") {
                Write-Log "BitLockerが有効になっています。無効化します..."
                try {
                    Disable-BitLocker -MountPoint $volume.MountPoint
                    Write-Log "✓ ドライブ $($volume.MountPoint) のBitLockerを無効化しました"
                } catch {
                    Write-Log "警告: ドライブ $($volume.MountPoint) のBitLocker無効化に失敗: $($_.Exception.Message)"
                }
            } else {
                Write-Log "ドライブ $($volume.MountPoint) のBitLockerは既に無効です"
            }
        }
    } else {
        Write-Log "BitLockerが有効なドライブはありません"
    }

    # ========================================
    # 2. レジストリ設定でBitLockerの自動暗号化を無効化
    # ========================================
    Write-Log "----------------------------------------"
    Write-Log "BitLocker自動暗号化の無効化"
    Write-Log "----------------------------------------"

    # BitLockerの自動デバイス暗号化を無効化
    $regPath1 = "HKLM:\SYSTEM\CurrentControlSet\Control\BitLocker"
    if (-not (Test-Path $regPath1)) {
        New-Item -Path $regPath1 -Force | Out-Null
        Write-Log "レジストリキーを作成: $regPath1"
    }

    Set-ItemProperty -Path $regPath1 -Name "PreventDeviceEncryption" -Value 1 -Type DWord -Force
    Write-Log "✓ BitLocker自動暗号化を無効化しました (PreventDeviceEncryption = 1)"

    # デバイス暗号化ポリシーの無効化
    $regPath2 = "HKLM:\SOFTWARE\Policies\Microsoft\FVE"
    if (-not (Test-Path $regPath2)) {
        New-Item -Path $regPath2 -Force | Out-Null
        Write-Log "レジストリキーを作成: $regPath2"
    }

    # OS ドライブの暗号化を無効化
    Set-ItemProperty -Path $regPath2 -Name "EnableBDEWithNoTPM" -Value 0 -Type DWord -Force
    Set-ItemProperty -Path $regPath2 -Name "UseAdvancedStartup" -Value 0 -Type DWord -Force
    Set-ItemProperty -Path $regPath2 -Name "UseTPM" -Value 0 -Type DWord -Force
    Set-ItemProperty -Path $regPath2 -Name "UseTPMPIN" -Value 0 -Type DWord -Force
    Set-ItemProperty -Path $regPath2 -Name "UseTPMKey" -Value 0 -Type DWord -Force
    Set-ItemProperty -Path $regPath2 -Name "UseTPMKeyPIN" -Value 0 -Type DWord -Force
    Write-Log "✓ BitLockerポリシー設定を無効化しました"

    # ========================================
    # 3. Windows Updateによる自動有効化を防止
    # ========================================
    Write-Log "----------------------------------------"
    Write-Log "Windows Update後の自動有効化を防止"
    Write-Log "----------------------------------------"

    # デバイス暗号化の自動有効化を防止
    $regPath3 = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceEncryption"
    if (-not (Test-Path $regPath3)) {
        New-Item -Path $regPath3 -Force | Out-Null
        Write-Log "レジストリキーを作成: $regPath3"
    }

    Set-ItemProperty -Path $regPath3 -Name "AllowDeviceEncryption" -Value 0 -Type DWord -Force
    Write-Log "✓ デバイス暗号化の自動有効化を防止しました"

    # ========================================
    # 4. Windows 11の自動デバイス暗号化を無効化
    # ========================================
    Write-Log "----------------------------------------"
    Write-Log "Windows 11自動デバイス暗号化の無効化"
    Write-Log "----------------------------------------"

    # Windows 11特有の自動暗号化設定
    $regPath4 = "HKLM:\SYSTEM\CurrentControlSet\Control\BitLocker\AutoEncrypt"
    if (-not (Test-Path $regPath4)) {
        New-Item -Path $regPath4 -Force | Out-Null
        Write-Log "レジストリキーを作成: $regPath4"
    }

    Set-ItemProperty -Path $regPath4 -Name "AllowStandardUserEncryption" -Value 0 -Type DWord -Force
    Write-Log "✓ 標準ユーザーによる暗号化を無効化しました"

    # ========================================
    # 5. TPMの自動プロビジョニングを無効化
    # ========================================
    Write-Log "----------------------------------------"
    Write-Log "TPM自動プロビジョニングの無効化"
    Write-Log "----------------------------------------"

    $regPath5 = "HKLM:\SOFTWARE\Policies\Microsoft\TPM"
    if (-not (Test-Path $regPath5)) {
        New-Item -Path $regPath5 -Force | Out-Null
        Write-Log "レジストリキーを作成: $regPath5"
    }

    Set-ItemProperty -Path $regPath5 -Name "OSManagedAuthLevel" -Value 0 -Type DWord -Force
    Write-Log "✓ TPM自動プロビジョニングを無効化しました"

    # ========================================
    # 6. 設定の確認
    # ========================================
    Write-Log "----------------------------------------"
    Write-Log "設定確認"
    Write-Log "----------------------------------------"

    $vol = Get-BitLockerVolume -MountPoint "C:" -ErrorAction SilentlyContinue
    if ($vol) {
        Write-Log "Cドライブ BitLocker状態: $($vol.ProtectionStatus)"
        Write-Log "暗号化率: $($vol.EncryptionPercentage)%"
    }

    $preventEncryption = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\BitLocker" -Name "PreventDeviceEncryption" -ErrorAction SilentlyContinue
    if ($preventEncryption) {
        Write-Log "PreventDeviceEncryption: $($preventEncryption.PreventDeviceEncryption)"
    }

    Write-Log "========================================="
    Write-Log "BitLocker無効化完了"
    Write-Log "========================================="
    Write-Log ""
    Write-Log "設定内容:"
    Write-Log "- BitLockerを無効化しました"
    Write-Log "- 自動暗号化を無効化しました"
    Write-Log "- Windows Update後も自動で有効になりません"

} catch {
    Write-Log "エラーが発生しました: $($_.Exception.Message)"
    Write-Log "スタックトレース: $($_.ScriptStackTrace)"
    throw
}

Write-Log "BitLocker無効化処理を終了します"
