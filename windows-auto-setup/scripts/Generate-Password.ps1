<#
.SYNOPSIS
    unattend.xml用パスワード生成ヘルパースクリプト

.DESCRIPTION
    このスクリプトは、unattend.xmlで使用するパスワードをBase64エンコードします。

.PARAMETER Password
    エンコードするパスワード（指定しない場合は対話的に入力）

.EXAMPLE
    .\Generate-Password.ps1
    パスワードを対話的に入力してエンコード

.EXAMPLE
    .\Generate-Password.ps1 -Password "Admin@2024"
    指定したパスワードをエンコード

.NOTES
    生成されたBase64文字列をunattend.xmlの<Value>タグに貼り付けてください
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$Password
)

# カラー出力関数
function Write-ColorOutput {
    param(
        [string]$Message,
        [ConsoleColor]$ForegroundColor = [ConsoleColor]::White
    )
    Write-Host $Message -ForegroundColor $ForegroundColor
}

Write-ColorOutput "========================================" -ForegroundColor Cyan
Write-ColorOutput "unattend.xml用パスワード生成ツール" -ForegroundColor Cyan
Write-ColorOutput "========================================" -ForegroundColor Cyan
Write-Host ""

# パスワードが指定されていない場合は対話的に入力
if ([string]::IsNullOrEmpty($Password)) {
    Write-ColorOutput "パスワードを入力してください:" -ForegroundColor Yellow
    Write-ColorOutput "（推奨: 8文字以上、大文字・小文字・数字・記号を含む）" -ForegroundColor Gray
    Write-Host ""

    # セキュアな入力
    $securePassword = Read-Host "パスワード" -AsSecureString
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword)
    $Password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
    [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)

    # 確認入力
    $securePasswordConfirm = Read-Host "パスワード（確認）" -AsSecureString
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePasswordConfirm)
    $PasswordConfirm = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
    [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)

    if ($Password -ne $PasswordConfirm) {
        Write-ColorOutput "`n✗ エラー: パスワードが一致しません" -ForegroundColor Red
        exit 1
    }
}

# パスワードの強度チェック
Write-Host ""
Write-ColorOutput "パスワード強度チェック:" -ForegroundColor Cyan
$strength = 0
$feedback = @()

if ($Password.Length -ge 8) {
    $strength++
    $feedback += "✓ 8文字以上"
} else {
    $feedback += "✗ 8文字未満（8文字以上を推奨）"
}

if ($Password -cmatch '[A-Z]') {
    $strength++
    $feedback += "✓ 大文字を含む"
} else {
    $feedback += "✗ 大文字を含まない"
}

if ($Password -cmatch '[a-z]') {
    $strength++
    $feedback += "✓ 小文字を含む"
} else {
    $feedback += "✗ 小文字を含まない"
}

if ($Password -match '\d') {
    $strength++
    $feedback += "✓ 数字を含む"
} else {
    $feedback += "✗ 数字を含まない"
}

if ($Password -match '[!@#$%^&*()_+\-=\[\]{};:''",.<>?/\\|`~]') {
    $strength++
    $feedback += "✓ 記号を含む"
} else {
    $feedback += "✗ 記号を含まない"
}

foreach ($item in $feedback) {
    if ($item -like "✓*") {
        Write-ColorOutput "  $item" -ForegroundColor Green
    } else {
        Write-ColorOutput "  $item" -ForegroundColor Yellow
    }
}

Write-Host ""
$strengthText = switch ($strength) {
    {$_ -le 2} { "弱い"; $color = [ConsoleColor]::Red }
    3 { "普通"; $color = [ConsoleColor]::Yellow }
    4 { "良い"; $color = [ConsoleColor]::Cyan }
    5 { "非常に強い"; $color = [ConsoleColor]::Green }
}
Write-ColorOutput "パスワード強度: $strengthText" -ForegroundColor $color

# Base64エンコード
Write-Host ""
Write-ColorOutput "Base64エンコード中..." -ForegroundColor Cyan

try {
    $bytes = [System.Text.Encoding]::Unicode.GetBytes($Password + "Password")
    $encodedPassword = [Convert]::ToBase64String($bytes)

    Write-Host ""
    Write-ColorOutput "========================================" -ForegroundColor Green
    Write-ColorOutput "エンコード完了！" -ForegroundColor Green
    Write-ColorOutput "========================================" -ForegroundColor Green
    Write-Host ""

    Write-ColorOutput "以下の文字列をunattend.xmlの<Value>タグに貼り付けてください:" -ForegroundColor Yellow
    Write-Host ""
    Write-ColorOutput $encodedPassword -ForegroundColor White
    Write-Host ""

    Write-ColorOutput "貼り付け箇所の例:" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  <Password>" -ForegroundColor DarkGray
    Write-ColorOutput "      <Value>$encodedPassword</Value>" -ForegroundColor Cyan
    Write-Host "      <PlainText>false</PlainText>" -ForegroundColor DarkGray
    Write-Host "  </Password>" -ForegroundColor DarkGray
    Write-Host ""

    # クリップボードにコピー（可能な場合）
    try {
        Set-Clipboard -Value $encodedPassword
        Write-ColorOutput "✓ クリップボードにコピーしました（Ctrl+Vで貼り付け可能）" -ForegroundColor Green
    } catch {
        Write-ColorOutput "※ クリップボードへのコピーに失敗しました（手動でコピーしてください）" -ForegroundColor Yellow
    }

    Write-Host ""
    Write-ColorOutput "========================================" -ForegroundColor Cyan

} catch {
    Write-ColorOutput "`n✗ エラー: エンコードに失敗しました" -ForegroundColor Red
    Write-ColorOutput $_.Exception.Message -ForegroundColor Red
    exit 1
}

# パスワードをメモリから消去
$Password = $null
$PasswordConfirm = $null
[System.GC]::Collect()

Write-Host ""
Write-ColorOutput "完了しました。" -ForegroundColor Green
