# USB起動ディスク作成手順

このガイドでは、Windows 11の自動セットアップ用USB起動ディスクの作成方法を説明します。

---

## 📋 必要なもの

- **USBメモリ**: 16GB以上（推奨: 32GB以上）
- **Windows 11 ISOファイル**: Microsoftの公式サイトからダウンロード
- **Rufus**: USB起動ディスク作成ツール（無料）
- **本リポジトリのファイル一式**

---

## 🔧 手順1: Windows 11 ISOファイルのダウンロード

1. Microsoft公式サイトにアクセス:
   ```
   https://www.microsoft.com/ja-jp/software-download/windows11
   ```

2. 「Windows 11 ディスク イメージ (ISO) をダウンロードする」セクションで:
   - Windows 11 (multi-edition ISO) を選択
   - 言語: 日本語 を選択
   - 64-bit ダウンロードをクリック

3. ダウンロードした ISOファイルを保存
   例: `C:\Downloads\Win11_Japanese_x64.iso`

---

## 🔧 手順2: Rufusのダウンロードとインストール

1. Rufus公式サイトにアクセス:
   ```
   https://rufus.ie/ja/
   ```

2. 最新版のRufusをダウンロード（インストール不要のポータブル版を推奨）

3. ダウンロードした `rufus-x.xx.exe` を実行

---

## 🔧 手順3: USB起動ディスクの作成

### 3-1. Rufusの設定

1. USBメモリをPCに接続

2. Rufusを起動して以下のように設定:

   | 項目 | 設定値 |
   |------|--------|
   | デバイス | 接続したUSBメモリを選択 |
   | ブートの種類 | 「選択」をクリックしてWindows 11 ISOファイルを選択 |
   | イメージオプション | **標準のWindowsインストール** |
   | パーティション構成 | GPT |
   | ターゲットシステム | UEFI (非CSM) |
   | ボリュームラベル | WIN11_AUTO_SETUP |
   | ファイルシステム | NTFS |
   | クラスターサイズ | 4096バイト (規定値) |

3. 「スタート」をクリック

4. 確認ダイアログが表示されたら「OK」をクリック
   - **警告**: USBメモリ内のデータはすべて削除されます

5. 書き込みが完了するまで待機（約10〜20分）

### 3-2. 自動セットアップファイルの配置

1. USB起動ディスクのルートに以下の構成でファイルを配置:

   ```
   E:\ (USBドライブ)
   ├── sources\
   │   └── $OEM$\
   │       └── $$\
   │           └── Setup\
   │               └── Scripts\
   │                   └── autounattend.xml (これはunattend.xmlをリネーム)
   ├── AutoSetup\
   │   └── scripts\
   │       ├── Main-Setup.ps1
   │       ├── 01-WindowsUpdate.ps1
   │       └── 02-InstallApps.ps1
   └── autounattend.xml (unattend.xmlをリネーム)
   ```

2. **重要**: 本リポジトリの `unattend.xml` を `autounattend.xml` にリネームしてUSBルートに配置

3. PowerShellスクリプトを配置:
   ```powershell
   # コマンドプロンプトまたはPowerShellで実行
   xcopy /E /I /Y "windows-auto-setup\scripts" "E:\AutoSetup\scripts"
   ```
   ※ `E:\` はUSBドライブのドライブレター

---

## 🔧 手順4: パスワード設定（重要）

`autounattend.xml` のパスワード部分を編集します。

1. USBドライブの `autounattend.xml` をテキストエディタで開く

2. 以下の部分を見つける:
   ```xml
   <Password>
       <Value>QQBkAG0AaQBuAEAAMgAwADIANABQAGEAcwBzAHcAbwByAGQA</Value>
       <PlainText>false</PlainText>
   </Password>
   ```

3. パスワードをBase64エンコード:

   **PowerShellで実行:**
   ```powershell
   # 管理者としてPowerShellを実行
   $password = "ここに設定したいパスワードを入力"  # 例: Admin@2024
   $bytes = [System.Text.Encoding]::Unicode.GetBytes($password + "Password")
   $encoded = [Convert]::ToBase64String($bytes)
   Write-Host "エンコード済みパスワード: $encoded"
   ```

4. 出力されたBase64文字列を `<Value>` タグに貼り付け

5. ファイルを保存

---

## 🔧 手順5: Windows 11インストールとOOBE自動化

### 5-1. BIOS/UEFI設定

1. PCを起動してBIOS/UEFI設定画面に入る
   - 通常は起動時に `F2`、`Del`、`F12` などのキーを押す

2. 以下を設定:
   - **Secure Boot**: 無効 (Disabled) ※Windows 11では有効推奨ですが、テスト時は無効化
   - **Boot Mode**: UEFI
   - **Boot Order**: USBを最優先に設定

3. 設定を保存して再起動

### 5-2. USBから起動

1. USBメモリを挿入したままPCを起動

2. USB起動ディスクから自動的にWindows 11のセットアップが開始されます

3. **自動的に以下が実行されます**:
   - OOBE（初回セットアップ画面）のスキップ
   - ローカルアカウント「owner」の作成
   - 地域・言語設定（日本語/日本）
   - プライバシー設定（全てオフ）

### 5-3. 初回ログオン後の自動処理

初回ログオン後、以下が自動実行されます:

1. **Windows Update** (約30分〜2時間)
   - 更新プログラムの確認
   - ダウンロード・インストール
   - 必要に応じて自動再起動
   - 更新がなくなるまで繰り返し

2. **アプリケーションインストール** (約10〜20分)
   - Google Chrome
   - Adobe Acrobat Reader

3. **完了通知**
   - ビープ音（3回）
   - デスクトップに「セットアップ完了.txt」を作成
   - メッセージボックスで通知

---

## 🔧 手順6: セットアップ完了確認

セットアップが完了したら、以下を確認してください:

### 確認項目

- [ ] ユーザー名が「owner」になっている
- [ ] Windows Updateが最新になっている（設定 → Windows Update）
- [ ] Google Chromeがインストールされている
- [ ] Adobe Acrobat Readerがインストールされている
- [ ] デスクトップに「セットアップ完了.txt」が作成されている

### ログファイルの確認

問題が発生した場合は、以下のログファイルを確認:

```
C:\AutoSetup\Logs\
├── Main-Setup.log          (メイン処理ログ)
├── WindowsUpdate.log       (Windows Updateログ)
└── AppInstall.log          (アプリインストールログ)
```

---

## 📝 トラブルシューティング

### 問題1: OOBEが自動スキップされない

**原因**: `autounattend.xml` が正しく読み込まれていない

**解決方法**:
1. `autounattend.xml` がUSBルートに配置されているか確認
2. ファイル名が正確に `autounattend.xml` になっているか確認（スペルミス注意）
3. XMLファイルの文法エラーがないか確認

### 問題2: 自動セットアップスクリプトが実行されない

**原因**: スクリプトファイルの配置場所が間違っている

**解決方法**:
1. `C:\AutoSetup\scripts\` にスクリプトファイルが配置されているか確認
2. PowerShellの実行ポリシーを確認:
   ```powershell
   Get-ExecutionPolicy
   ```
   Restrictedの場合は変更が必要

### 問題3: Windows Updateが失敗する

**原因**: ネットワーク接続の問題

**解決方法**:
1. インターネット接続を確認
2. 手動でWindows Updateを実行してエラーメッセージを確認
3. ログファイル `C:\AutoSetup\Logs\WindowsUpdate.log` を確認

### 問題4: アプリがインストールされない

**原因**: ダウンロード失敗またはインストーラーの互換性問題

**解決方法**:
1. インターネット接続を確認
2. ログファイル `C:\AutoSetup\Logs\AppInstall.log` を確認
3. 手動でインストールを試みる

---

## 🎯 49台展開時の効率化

### 一括展開の推奨手順

1. **マスターUSBの作成**
   - 上記手順で1つのUSBを完璧に作成
   - すべての設定とスクリプトが正常に動作することを確認

2. **USBの複製**
   - `dd` コマンドや専用ツール（Win32 Disk Imager等）でUSBイメージを作成
   - 複数のUSBメモリに同じイメージを書き込み

3. **並列実行**
   - 複数台のPCで同時にセットアップを実行
   - 1台あたり約2〜4時間で完了（ネットワーク速度に依存）

4. **進捗管理**
   - 各PCのIPアドレスとセットアップ状態をスプレッドシート等で管理
   - 完了通知のビープ音で完了を確認

### 注意事項

- ネットワーク帯域幅を考慮（同時にWindows Updateを実行すると遅くなる可能性）
- プロダクトキーの管理（ボリュームライセンスの場合）
- コンピューター名の重複を避ける（必要に応じて `unattend.xml` を修正）

---

## 📞 サポート

問題が解決しない場合は、以下の情報を添えてサポートに連絡してください:

- Windows 11のバージョン
- エラーメッセージ
- ログファイルの内容
- 実行した手順の詳細

---

**作成日**: 2025年12月6日
**対象バージョン**: Windows 11 (22H2以降)
