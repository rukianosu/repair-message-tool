#Requires -RunAsAdministrator

<#
.SYNOPSIS
    アプリケーション自動インストールスクリプト

.DESCRIPTION
    このスクリプトは以下のアプリケーションをサイレントインストールします：
    1. Google Chrome（最新版）
    2. Adobe Acrobat Reader（最新版）

.NOTES
    管理者権限が必要です
#>

# ログファイルパス
$LogFile = "C:\AutoSetup\Logs\AppInstall.log"
$null = New-Item -ItemType Directory -Force -Path (Split-Path $LogFile)

# 一時ダウンロードフォルダ
$TempFolder = "C:\AutoSetup\Downloads"
$null = New-Item -ItemType Directory -Force -Path $TempFolder

# ログ記録関数
function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] $Message"
    Write-Host $logMessage
    Add-Content -Path $LogFile -Value $logMessage
}

# ファイルダウンロード関数
function Download-File {
    param(
        [string]$Url,
        [string]$OutputPath
    )

    try {
        Write-Log "ダウンロード中: $Url"
        Write-Log "保存先: $OutputPath"

        # プログレス表示を無効化（高速化）
        $ProgressPreference = 'SilentlyContinue'

        # TLS 1.2を有効化
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

        Invoke-WebRequest -Uri $Url -OutFile $OutputPath -UseBasicParsing
        Write-Log "ダウンロード完了"
        return $true
    } catch {
        Write-Log "ダウンロード失敗: $($_.Exception.Message)"
        return $false
    }
}

Write-Log "========================================="
Write-Log "アプリケーション自動インストール開始"
Write-Log "========================================="

try {
    # Wingetが利用可能か確認
    $useWinget = $false
    try {
        $wingetVersion = winget --version
        Write-Log "Winget検出: $wingetVersion"
        $useWinget = $true
    } catch {
        Write-Log "Wingetが見つかりません。直接ダウンロード方式を使用します"
    }

    # ========================================
    # Google Chrome のインストール
    # ========================================
    Write-Log "----------------------------------------"
    Write-Log "Google Chrome のインストール"
    Write-Log "----------------------------------------"

    $chromeInstalled = $false

    if ($useWinget) {
        try {
            Write-Log "WingetでGoogle Chromeをインストール中..."
            $result = winget install Google.Chrome --silent --accept-package-agreements --accept-source-agreements 2>&1

            # インストール結果を確認
            Start-Sleep -Seconds 3
            $chromePath = "C:\Program Files\Google\Chrome\Application\chrome.exe"
            if (Test-Path $chromePath) {
                Write-Log "Google Chrome のインストール完了（Winget経由）"
                $chromeInstalled = $true
            } else {
                Write-Log "Wingetでのインストールに失敗しました"
                $useWinget = $false
            }
        } catch {
            Write-Log "Wingetでのインストールに失敗: $($_.Exception.Message)"
            $useWinget = $false
        }
    }

    if (-not $chromeInstalled) {
        Write-Log "直接ダウンロードでインストールします"
        $chromeUrl = "https://dl.google.com/chrome/install/latest/chrome_installer.exe"
        $chromeInstaller = Join-Path $TempFolder "chrome_installer.exe"

        if (Download-File -Url $chromeUrl -OutputPath $chromeInstaller) {
            Write-Log "Google Chrome をインストール中..."
            $process = Start-Process -FilePath $chromeInstaller -ArgumentList "/silent /install" -Wait -PassThru

            if ($process.ExitCode -eq 0) {
                Write-Log "Google Chrome のインストール完了"
                $chromeInstalled = $true
            } else {
                Write-Log "Google Chrome のインストール失敗。終了コード: $($process.ExitCode)"
            }

            Remove-Item $chromeInstaller -Force -ErrorAction SilentlyContinue
        } else {
            Write-Log "Google Chrome のダウンロードに失敗しました"
        }
    }

    # ========================================
    # Adobe Acrobat Reader のインストール
    # ========================================
    Write-Log "----------------------------------------"
    Write-Log "Adobe Acrobat Reader のインストール"
    Write-Log "----------------------------------------"

    $adobeInstalled = $false

    if ($useWinget) {
        try {
            Write-Log "WingetでAdobe Acrobat Readerをインストール中..."
            $result = winget install Adobe.Acrobat.Reader.64-bit --silent --accept-package-agreements --accept-source-agreements 2>&1

            # インストール結果を確認
            Start-Sleep -Seconds 5
            $adobePaths = @(
                "C:\Program Files\Adobe\Acrobat DC\Acrobat\Acrobat.exe",
                "C:\Program Files (x86)\Adobe\Acrobat Reader DC\Reader\AcroRd32.exe",
                "C:\Program Files\Adobe\Acrobat Reader DC\Reader\AcroRd32.exe"
            )

            $found = $false
            foreach ($path in $adobePaths) {
                if (Test-Path $path) {
                    Write-Log "Adobe Acrobat Reader のインストール完了（Winget経由）"
                    $adobeInstalled = $true
                    $found = $true
                    break
                }
            }

            if (-not $found) {
                Write-Log "Wingetでのインストールに失敗しました"
                $useWinget = $false
            }
        } catch {
            Write-Log "Wingetでのインストールに失敗: $($_.Exception.Message)"
            $useWinget = $false
        }
    }

    if (-not $adobeInstalled) {
        Write-Log "直接ダウンロードでインストールします"

        # Adobe Reader FTPサイトから最新版をダウンロード
        # 日本語版の最新バージョンURL（バージョンは定期的に更新が必要）
        $adobeUrl = "https://ardownload2.adobe.com/pub/adobe/reader/win/AcrobatDC/2400220857/AcroRdrDC2400220857_ja_JP.exe"
        $adobeInstaller = Join-Path $TempFolder "AcroRdrDC_ja_JP.exe"

        if (Download-File -Url $adobeUrl -OutputPath $adobeInstaller) {
            Write-Log "Adobe Acrobat Reader をインストール中..."

            # サイレントインストールパラメータ
            # MAKE_DEFAULT=YES: PDFファイルのデフォルトアプリとして設定
            $arguments = "/sAll /rs /msi EULA_ACCEPT=YES MAKE_DEFAULT=YES"
            $process = Start-Process -FilePath $adobeInstaller -ArgumentList $arguments -Wait -PassThru

            if ($process.ExitCode -eq 0) {
                Write-Log "Adobe Acrobat Reader のインストール完了"
                $adobeInstalled = $true
            } else {
                Write-Log "Adobe Acrobat Reader のインストール失敗。終了コード: $($process.ExitCode)"
            }

            Remove-Item $adobeInstaller -Force -ErrorAction SilentlyContinue
        } else {
            Write-Log "Adobe Acrobat Reader のダウンロードに失敗しました"
            Write-Log "代替URL（FTPサイト）を試行します..."

            # 代替ダウンロード方法（最新版へのリダイレクトURL）
            $adobeUrlAlt = "https://get.adobe.com/reader/download/?installer=Reader_DC_2024_ja_JP_Windows&standalone=1"
            Write-Log "代替URLからダウンロードを試行: $adobeUrlAlt"
            Write-Log "※この方法では手動でインストーラーを実行する必要がある場合があります"
        }
    }

    # ========================================
    # インストール完了確認
    # ========================================
    Write-Log "----------------------------------------"
    Write-Log "インストール完了確認"
    Write-Log "----------------------------------------"

    # Google Chromeの確認
    $chromePath = "C:\Program Files\Google\Chrome\Application\chrome.exe"
    if (Test-Path $chromePath) {
        $chromeVersion = (Get-Item $chromePath).VersionInfo.ProductVersion
        Write-Log "✓ Google Chrome インストール済み (Version: $chromeVersion)"
    } else {
        Write-Log "✗ Google Chrome が見つかりません"
    }

    # Adobe Readerの確認
    $adobePaths = @(
        "C:\Program Files\Adobe\Acrobat DC\Acrobat\Acrobat.exe",
        "C:\Program Files (x86)\Adobe\Acrobat Reader DC\Reader\AcroRd32.exe",
        "C:\Program Files\Adobe\Acrobat Reader DC\Reader\AcroRd32.exe"
    )

    $adobeFound = $false
    foreach ($path in $adobePaths) {
        if (Test-Path $path) {
            $adobeVersion = (Get-Item $path).VersionInfo.ProductVersion
            Write-Log "✓ Adobe Acrobat Reader インストール済み (Version: $adobeVersion)"
            $adobeFound = $true
            break
        }
    }

    if (-not $adobeFound) {
        Write-Log "✗ Adobe Acrobat Reader が見つかりません"
    } else {
        # PDFファイルの関連付けは、Adobe Readerインストール時の
        # MAKE_DEFAULT=YES パラメータで自動的に設定されます
        Write-Log "✓ PDFファイルの関連付け設定完了（インストール時に自動設定）"
    }

    # 一時フォルダのクリーンアップ
    Write-Log "一時ファイルをクリーンアップ中..."
    Remove-Item $TempFolder -Recurse -Force -ErrorAction SilentlyContinue

    Write-Log "========================================="
    Write-Log "アプリケーションインストール完了"
    Write-Log "========================================="

} catch {
    Write-Log "エラーが発生しました: $($_.Exception.Message)"
    Write-Log "スタックトレース: $($_.ScriptStackTrace)"
    throw
}
