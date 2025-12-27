#Requires -RunAsAdministrator

<#
.SYNOPSIS
    BitLocker / デバイス暗号化 完全停止・復号スクリプト（ルキテック納品基準準拠）

.DESCRIPTION
    Windows 初期設定（OOBE）後に自動で走る BitLocker / デバイス暗号化を確実に停止（復号）し、
    納品基準である FullyDecrypted を満たしているか判定してログを残します。

    納品基準（ルキテックルール）：
    - 納品OK：VolumeStatus = FullyDecrypted かつ EncryptionPercentage = 0
    - それ以外は納品NG

.NOTES
    管理者権限が必須です
    対象：OSドライブ C: のみ
#>

# ログファイルパス
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$LogFile = "C:\RukiTech\Logs\BitLockerGuard_$timestamp.txt"
$null = New-Item -ItemType Directory -Force -Path (Split-Path $LogFile)

# ログ記録関数
function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"  # INFO, WARN, ERROR, OK, NG
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"

    # コンソール出力（色分け）
    switch ($Level) {
        "OK"    { Write-Host $logMessage -ForegroundColor Green }
        "NG"    { Write-Host $logMessage -ForegroundColor Red }
        "WARN"  { Write-Host $logMessage -ForegroundColor Yellow }
        "ERROR" { Write-Host $logMessage -ForegroundColor Red }
        default { Write-Host $logMessage }
    }

    # ファイル出力
    Add-Content -Path $LogFile -Value $logMessage
}

# 納品基準チェック関数
function Test-DeliveryStandard {
    param($Volume)

    $isOK = ($Volume.VolumeStatus -eq "FullyDecrypted") -and ($Volume.EncryptionPercentage -eq 0)
    return $isOK
}

Write-Log "=========================================" "INFO"
Write-Log "BitLocker / デバイス暗号化 完全停止スクリプト" "INFO"
Write-Log "ルキテック納品基準準拠" "INFO"
Write-Log "=========================================" "INFO"

try {
    # 管理者権限チェック
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    $isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    if (-not $isAdmin) {
        Write-Log "エラー: 管理者権限で実行してください" "ERROR"
        Write-Log "右クリック → 「管理者として実行」で起動してください" "ERROR"
        exit 1
    }

    Write-Log "管理者権限確認：OK" "INFO"

    # C:ドライブのBitLocker状態を取得
    Write-Log "C:ドライブのBitLocker状態を取得中..." "INFO"

    try {
        $volume = Get-BitLockerVolume -MountPoint "C:" -ErrorAction Stop
    } catch {
        Write-Log "BitLocker機能が利用できません（Homeエディション等）" "WARN"
        Write-Log "デバイス暗号化の状態を確認します..." "INFO"

        # Windows 11のデバイス暗号化を無効化
        try {
            $regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\BitLocker"
            if (-not (Test-Path $regPath)) {
                New-Item -Path $regPath -Force | Out-Null
            }
            Set-ItemProperty -Path $regPath -Name "PreventDeviceEncryption" -Value 1 -Type DWord -Force
            Write-Log "デバイス暗号化の自動有効化を無効化しました" "OK"
            Write-Log "納品判定：OK（BitLocker機能なし）" "OK"
            exit 0
        } catch {
            Write-Log "エラー: $($_.Exception.Message)" "ERROR"
            exit 1
        }
    }

    Write-Log "----------------------------------------" "INFO"
    Write-Log "現在の状態：" "INFO"
    Write-Log "  VolumeStatus: $($volume.VolumeStatus)" "INFO"
    Write-Log "  EncryptionPercentage: $($volume.EncryptionPercentage)%" "INFO"
    Write-Log "  ProtectionStatus: $($volume.ProtectionStatus)" "INFO"
    Write-Log "----------------------------------------" "INFO"

    # ========================================
    # 判定ロジック
    # ========================================

    # A) すでに解除済み
    if (Test-DeliveryStandard -Volume $volume) {
        Write-Log "=========================================" "OK"
        Write-Log "納品判定：OK" "OK"
        Write-Log "C:ドライブは完全に復号されています" "OK"
        Write-Log "VolumeStatus = FullyDecrypted" "OK"
        Write-Log "EncryptionPercentage = 0%" "OK"
        Write-Log "=========================================" "OK"

        # 念のため自動暗号化を無効化
        Write-Log "自動暗号化の無効化設定を実行します..." "INFO"
        $regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\BitLocker"
        if (-not (Test-Path $regPath)) {
            New-Item -Path $regPath -Force | Out-Null
        }
        Set-ItemProperty -Path $regPath -Name "PreventDeviceEncryption" -Value 1 -Type DWord -Force
        Write-Log "自動暗号化を無効化しました" "OK"

        exit 0
    }

    # B) 暗号化中／準備中
    if ($volume.VolumeStatus -eq "EncryptionInProgress" -or $volume.EncryptionPercentage -gt 0) {
        Write-Log "=========================================" "WARN"
        Write-Log "警告：BitLockerが暗号化中です" "WARN"
        Write-Log "暗号化率: $($volume.EncryptionPercentage)%" "WARN"
        Write-Log "即座に停止（復号）を開始します" "WARN"
        Write-Log "=========================================" "WARN"

        # BitLockerを無効化（復号開始）
        Write-Log "Disable-BitLocker を実行中..." "INFO"
        try {
            Disable-BitLocker -MountPoint "C:" -ErrorAction Stop
            Write-Log "Disable-BitLocker 実行成功" "OK"
        } catch {
            Write-Log "エラー: Disable-BitLocker に失敗しました" "ERROR"
            Write-Log "エラー詳細: $($_.Exception.Message)" "ERROR"
            Write-Log "納品判定：NG（復号開始失敗）" "NG"
            exit 1
        }

        # 状態を再取得
        Start-Sleep -Seconds 3
        $volume = Get-BitLockerVolume -MountPoint "C:"

        Write-Log "----------------------------------------" "INFO"
        Write-Log "復号開始後の状態：" "INFO"
        Write-Log "  VolumeStatus: $($volume.VolumeStatus)" "INFO"
        Write-Log "  EncryptionPercentage: $($volume.EncryptionPercentage)%" "INFO"
        Write-Log "----------------------------------------" "INFO"

        if ($volume.VolumeStatus -eq "DecryptionInProgress") {
            Write-Log "復号処理が開始されました" "OK"
            # C) 復号中の処理へ
        } elseif (Test-DeliveryStandard -Volume $volume) {
            Write-Log "即座に復号が完了しました" "OK"
            Write-Log "納品判定：OK" "OK"
            exit 0
        } else {
            Write-Log "警告: 予期しない状態です" "WARN"
            Write-Log "復号監視を続行します..." "INFO"
        }
    }

    # C) 復号中
    if ($volume.VolumeStatus -eq "DecryptionInProgress") {
        Write-Log "=========================================" "INFO"
        Write-Log "復号処理を監視します" "INFO"
        Write-Log "最大監視時間: 60分" "INFO"
        Write-Log "確認間隔: 30秒" "INFO"
        Write-Log "=========================================" "INFO"

        $maxWaitMinutes = 60
        $intervalSeconds = 30
        $maxIterations = ($maxWaitMinutes * 60) / $intervalSeconds
        $iteration = 0

        while ($iteration -lt $maxIterations) {
            $iteration++
            $elapsedMinutes = [math]::Round(($iteration * $intervalSeconds) / 60, 1)

            Write-Log "監視中 [$elapsedMinutes 分経過] 暗号化率: $($volume.EncryptionPercentage)%" "INFO"

            # 納品基準を満たしているかチェック
            if (Test-DeliveryStandard -Volume $volume) {
                Write-Log "=========================================" "OK"
                Write-Log "復号完了！" "OK"
                Write-Log "経過時間: $elapsedMinutes 分" "OK"
                Write-Log "納品判定：OK" "OK"
                Write-Log "VolumeStatus = FullyDecrypted" "OK"
                Write-Log "EncryptionPercentage = 0%" "OK"
                Write-Log "=========================================" "OK"

                # 自動暗号化を無効化
                $regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\BitLocker"
                if (-not (Test-Path $regPath)) {
                    New-Item -Path $regPath -Force | Out-Null
                }
                Set-ItemProperty -Path $regPath -Name "PreventDeviceEncryption" -Value 1 -Type DWord -Force
                Write-Log "自動暗号化を無効化しました" "OK"

                exit 0
            }

            # まだ復号中
            Start-Sleep -Seconds $intervalSeconds
            $volume = Get-BitLockerVolume -MountPoint "C:"
        }

        # タイムアウト
        Write-Log "=========================================" "NG"
        Write-Log "タイムアウト：60分以内に復号が完了しませんでした" "NG"
        Write-Log "現在の暗号化率: $($volume.EncryptionPercentage)%" "NG"
        Write-Log "納品判定：NG（復号中のため納品不可）" "NG"
        Write-Log "=========================================" "NG"
        Write-Log "推奨アクション：" "WARN"
        Write-Log "1. 復号が完了するまで待機してください" "WARN"
        Write-Log "2. 電源を入れたまま放置してください" "WARN"
        Write-Log "3. 復号完了後、再度このスクリプトを実行してください" "WARN"
        exit 1
    }

    # D) Suspended / Locked / その他
    Write-Log "=========================================" "NG"
    Write-Log "納品判定：NG" "NG"
    Write-Log "予期しない状態です" "NG"
    Write-Log "VolumeStatus: $($volume.VolumeStatus)" "NG"
    Write-Log "EncryptionPercentage: $($volume.EncryptionPercentage)%" "NG"
    Write-Log "=========================================" "NG"
    Write-Log "推奨アクション：" "WARN"

    if ($volume.ProtectionStatus -eq "On") {
        Write-Log "1. BitLockerが有効になっています" "WARN"
        Write-Log "2. 手動で無効化してください：" "WARN"
        Write-Log "   コントロールパネル → BitLocker → 無効化" "WARN"
    } else {
        Write-Log "1. 状態を確認してください" "WARN"
        Write-Log "2. システムを再起動してください" "WARN"
        Write-Log "3. 再度このスクリプトを実行してください" "WARN"
    }

    exit 1

} catch {
    Write-Log "=========================================" "ERROR"
    Write-Log "予期しないエラーが発生しました" "ERROR"
    Write-Log "エラー内容: $($_.Exception.Message)" "ERROR"
    Write-Log "スタックトレース: $($_.ScriptStackTrace)" "ERROR"
    Write-Log "=========================================" "ERROR"
    exit 1
}
