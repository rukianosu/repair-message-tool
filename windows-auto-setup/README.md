# Windows 11 完全自動セットアップシステム

Windows初期化後のセットアップを完全自動化するシステムです。OOBE（Out-of-Box Experience）のスキップから、Windows Update、アプリケーションインストールまで、すべて自動で実行します。

---

## 🎯 概要

このシステムは、Windows 11の初期セットアップを完全自動化し、手作業を一切不要にします。

### 主な機能

✅ **OOBE自動スキップ**
- Microsoftアカウント不要
- ローカルアカウント自動作成（ユーザー名: owner）
- 地域・言語設定（日本/日本語）
- プライバシー設定を全てオフ

✅ **Windows Update完全自動実行**
- 更新プログラムの自動確認
- 自動ダウンロード・インストール
- 必要に応じて自動再起動
- 更新がなくなるまで繰り返し実行

✅ **アプリケーション自動インストール**
- Google Chrome（最新版）
- Adobe Acrobat Reader（最新版）
- サイレントインストール（画面操作不要）
- PDFファイルをAdobe Readerで開く設定

✅ **BitLocker自動無効化**
- BitLockerを無効化
- 今後の大型アップデートでも自動で有効にならないよう設定
- お客様への引き渡し時に暗号化で困らない

✅ **完了通知**
- ビープ音で完了を通知
- デスクトップに「セットアップ完了.txt」を作成
- メッセージボックスで通知

---

## 📁 ファイル構成

```
windows-auto-setup/
├── README.md                      # このファイル
├── USB-Setup-Guide.md             # USB起動ディスク作成手順
├── unattend.xml                   # OOBE自動化設定ファイル
├── セットアップ実行.bat            # ワンクリック実行バッチファイル（既存Windows用）
└── scripts/
    ├── Main-Setup.ps1             # メイン統合スクリプト
    ├── 01-WindowsUpdate.ps1       # Windows Update自動実行
    ├── 02-InstallApps.ps1         # アプリ自動インストール
    ├── 03-DisableBitLocker.ps1    # BitLocker無効化
    └── Generate-Password.ps1      # パスワードエンコードヘルパー
```

---

## 🚀 実行方法

このシステムには2つの実行方法があります:

### 方法1: USB起動ディスクから自動実行（推奨）

Windows 11インストール時にOOBEから完全自動化します。

**👉 詳細は [USB-Setup-Guide.md](./USB-Setup-Guide.md) を参照してください**

**概要:**
1. USB起動ディスクを作成
2. `unattend.xml` を `autounattend.xml` にリネームしてUSBルートに配置
3. スクリプトを `AutoSetup\scripts\` に配置
4. USBから起動してWindows 11をインストール
5. 自動的にすべてのセットアップが実行されます

---

### 方法2: 既存のWindowsで実行（バッチファイル使用・推奨）

すでにWindows 11がインストール済みの場合の実行方法です。

#### 📌 簡単実行（バッチファイル使用）

**最も簡単な方法です。USBメモリまたはダウンロードしたフォルダから直接実行できます。**

1. このリポジトリをダウンロード:
   ```
   USBメモリにコピー、または
   git clone https://github.com/your-repo/windows-auto-setup.git
   ```

2. **`セットアップ実行.bat` を右クリック → 「管理者として実行」**

   これだけです！バッチファイルが自動的に以下を実行します:
   - 管理者権限の確認
   - スクリプトを `C:\AutoSetup` にコピー
   - PowerShell実行ポリシーの変更
   - メインセットアップスクリプトの起動

#### 💻 手動実行（PowerShellコマンド使用）

バッチファイルを使わず、手動でコマンドを実行したい場合:

**ステップ1: ファイルの配置**

```powershell
# スクリプトを C:\AutoSetup に配置
xcopy /E /I /Y "windows-auto-setup\scripts" "C:\AutoSetup\scripts"
```

**ステップ2: PowerShell実行ポリシーの変更**

管理者としてPowerShellを実行し、以下のコマンドを実行:

```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope LocalMachine -Force
```

**ステップ3: メインスクリプトの実行**

```powershell
C:\AutoSetup\scripts\Main-Setup.ps1
```

#### 注意事項

- **管理者権限が必要です**
- **インターネット接続が必要です**
- Windows Updateで複数回再起動する可能性があります
- 再起動後は自動的にスクリプトが継続実行されます

---

## ⚙️ ユーザーアカウント設定

### デフォルト設定

- **ユーザー名**: owner
- **パスワード**: なし（空欄）
- **権限**: 管理者（Administrators グループ）
- **パスワード有効期限**: 無効

### パスワードを設定したい場合

お客様への引き渡し時にパスワードを設定したい場合は、`unattend.xml` を編集してください。

1. PowerShellで以下のコマンドを実行してパスワードをエンコード:
   ```powershell
   $password = "設定したいパスワード"
   $bytes = [System.Text.Encoding]::Unicode.GetBytes($password + "Password")
   $encoded = [Convert]::ToBase64String($bytes)
   Write-Host "エンコード済みパスワード: $encoded"
   ```

2. `unattend.xml` の以下の部分を編集:
   ```xml
   <Password>
       <Value>ここにエンコードされたパスワードを貼り付け</Value>
       <PlainText>false</PlainText>
   </Password>
   ```

---

## 📊 セットアップ時間の目安

| 処理 | 所要時間 |
|------|----------|
| Windows 11インストール | 約15〜30分 |
| OOBE自動スキップ | 約1〜2分 |
| Windows Update | 約30分〜2時間 |
| アプリインストール | 約10〜20分 |
| **合計** | **約1〜3時間** |

※ネットワーク速度、PC性能、更新プログラムの数により変動します。

---

## 🔍 ログファイルの確認

セットアップ中に問題が発生した場合は、以下のログファイルを確認してください:

```
C:\AutoSetup\Logs\
├── Main-Setup.log          # メイン処理ログ
├── WindowsUpdate.log       # Windows Updateログ
└── AppInstall.log          # アプリインストールログ
```

ログの確認方法:
```powershell
# PowerShellで実行
Get-Content C:\AutoSetup\Logs\Main-Setup.log -Tail 50
```

---

## 🔧 カスタマイズ

### インストールするアプリを追加・変更

`scripts/02-InstallApps.ps1` を編集して、インストールするアプリを追加・変更できます。

**例: Microsoft Office を追加**

```powershell
# scripts/02-InstallApps.ps1 の最後に追加
Write-Log "----------------------------------------"
Write-Log "Microsoft Office のインストール"
Write-Log "----------------------------------------"

if ($useWinget) {
    winget install Microsoft.Office --silent --accept-package-agreements --accept-source-agreements
    Write-Log "Microsoft Office のインストール完了"
}
```

### コンピューター名を固定

`unattend.xml` の以下の部分を編集:

```xml
<!-- 現在（ランダム生成） -->
<ComputerName>*</ComputerName>

<!-- 固定名に変更 -->
<ComputerName>DESKTOP-001</ComputerName>
```

### プライバシー設定を変更

`unattend.xml` の以下の部分を編集:

```xml
<ProtectYourPC>3</ProtectYourPC>  <!-- 全てオフ -->
<!-- 以下のいずれかに変更可能 -->
<!-- 1: すべて有効 -->
<!-- 2: 推奨設定 -->
<!-- 3: すべて無効 -->
```

---

## 🎯 49台展開時の推奨手順

### 準備

1. **マスターUSBの作成**
   - 1台でテストして動作を確認
   - 設定を完璧に調整

2. **USBの複製**
   - Win32 Disk ImagerやRufusでUSBイメージを作成
   - 複数のUSBメモリに書き込み

3. **ネットワーク環境の確認**
   - 十分な帯域幅を確保
   - 同時接続数を考慮

### 展開

1. **並列実行**
   - 5〜10台ずつグループ化して実行
   - ネットワーク負荷を分散

2. **進捗管理**
   - スプレッドシートで進捗を管理
   - ビープ音で完了を確認

3. **検証**
   - すべてのPCでセットアップ完了を確認
   - ログファイルでエラーがないか確認

### 効率化のヒント

- **ローカルキャッシュサーバー**: WSUSを使用してWindows Updateをローカル配信
- **バッチ処理**: 時間帯をずらして実行し、ネットワーク負荷を分散
- **監視ツール**: PowerShell Remoting等で一括監視

---

## 🐛 トラブルシューティング

### よくある問題と解決方法

#### 問題1: スクリプトが実行されない

**エラーメッセージ**: 「このシステムではスクリプトの実行が無効になっているため...」

**解決方法**:
```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope LocalMachine -Force
```

#### 問題2: Windows Updateが失敗する

**原因**: PSWindowsUpdateモジュールのインストール失敗

**解決方法**:
```powershell
# NuGetプロバイダーを手動インストール
Install-PackageProvider -Name NuGet -Force
# PSWindowsUpdateモジュールを手動インストール
Install-Module -Name PSWindowsUpdate -Force
```

#### 問題3: アプリがインストールされない

**原因**: ダウンロードURLの変更またはネットワーク問題

**解決方法**:
1. インターネット接続を確認
2. ログファイル (`C:\AutoSetup\Logs\AppInstall.log`) を確認
3. 手動でアプリをインストール

#### 問題4: 再起動後にスクリプトが継続されない

**原因**: スケジュールタスクの作成失敗

**解決方法**:
```powershell
# スケジュールタスクを手動で確認
Get-ScheduledTask -TaskName "AutoSetup-Continue"

# 存在しない場合は再作成
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -File C:\AutoSetup\scripts\Main-Setup.ps1"
$trigger = New-ScheduledTaskTrigger -AtLogOn
$principal = New-ScheduledTaskPrincipal -UserId "owner" -RunLevel Highest
Register-ScheduledTask -TaskName "AutoSetup-Continue" -Action $action -Trigger $trigger -Principal $principal -Force
```

---

## 📋 システム要件

- **OS**: Windows 11 (22H2以降推奨)
- **メモリ**: 4GB以上（8GB以上推奨）
- **ストレージ**: 64GB以上
- **ネットワーク**: インターネット接続必須
- **権限**: 管理者権限必須

---

## 🔐 セキュリティに関する注意事項

1. **パスワード管理**
   - `unattend.xml` にパスワードが含まれています
   - ファイルの取り扱いに注意してください
   - 本番環境では強力なパスワードを設定してください

2. **実行ポリシー**
   - スクリプト実行のため `ExecutionPolicy` を `Bypass` に設定します
   - セットアップ完了後、必要に応じて元に戻してください

3. **プライバシー設定**
   - デフォルトではすべてのプライバシー設定をオフにしています
   - 必要に応じて `unattend.xml` を編集してください

---

## 📝 ライセンス

このプロジェクトはMITライセンスの下で公開されています。

---

## 🤝 貢献

バグ報告、機能リクエスト、プルリクエストを歓迎します。

---

## 📞 サポート

問題が発生した場合は、以下の情報を添えてIssueを作成してください:

- Windows 11のバージョン
- エラーメッセージ
- ログファイルの内容
- 実行した手順の詳細

---

## 📅 更新履歴

### v1.0.0 (2025-12-06)
- 初回リリース
- OOBE自動スキップ機能
- Windows Update自動実行機能
- アプリ自動インストール機能（Chrome、Adobe Reader）
- 完了通知機能

---

**作成日**: 2025年12月6日
**対象バージョン**: Windows 11 (22H2以降)
**テスト環境**: Windows 11 Pro 23H2

---

## 🎓 参考資料

- [Microsoft Docs - Unattend settings](https://docs.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/)
- [PSWindowsUpdate Module](https://www.powershellgallery.com/packages/PSWindowsUpdate)
- [Rufus - Create bootable USB drives](https://rufus.ie/)
