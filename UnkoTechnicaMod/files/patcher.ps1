#=============================================================================
# UNKO TECHNICA 非公式MOD インストーラー / Unofficial MOD installer
#  - 実行環境 NW.js を新しい版に入れ替え（GPU描画を有効にして画面のカクつきを解消）
#  - CANNONの向きズレ修正プラグインを追加
# Windows PowerShell 5.1 + WinForms。管理者権限は不要（Steamのフォルダに書き込めれば動く）
#=============================================================================
# 通常は引数なしで起動（画面が出る）。-Action を付けると画面なしで実行（動作確認・サポート用）
param(
    [ValidateSet('', 'apply', 'revert', 'status', 'download')][string]$Action = '',
    [string]$GameDir = '',
    [string]$WorkDirOverride = '',
    [string]$TestUrl = '',
    [string]$TestSha = ''
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.Windows.Forms.Application]::EnableVisualStyles()
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

#---------------------------------------------------------------------------
# 設定
#---------------------------------------------------------------------------
$ModVersion = '1.0.0'
$AppId      = '3101010'
$GameTitle  = 'ウンコテクニカ'
$Nw = @{
    Version = '0.118.0'
    File    = 'nwjs-v0.118.0-win-x64.zip'
    Url     = 'https://dl.nwjs.io/v0.118.0/nwjs-v0.118.0-win-x64.zip'
    Sha256  = '43A03D39A2402F2F9CD9982B56D8DD513D8E4F289CD34253AF7DEB8C45E58DF2'
    Folder  = 'nwjs-v0.118.0-win-x64'
}
$Here      = $PSScriptRoot
$FixSrc    = Join-Path $Here 'CannonPhaseFix.js'
$WorkDir   = if ($WorkDirOverride) { $WorkDirOverride } else { Join-Path $env:LOCALAPPDATA 'UnkoTechnicaMod' }
if ($TestUrl) { $Nw.Url = $TestUrl; $Nw.Sha256 = $TestSha.ToUpper() }
$LogFile   = Join-Path $WorkDir 'mod_log.txt'
$SaveBkDir = Join-Path $WorkDir 'save_backups'
$FixEntry  = '{"name":"CannonPhaseFix","status":true,"description":"[Unofficial MOD] CANNON fix","parameters":{}}'
$Utf8      = New-Object System.Text.UTF8Encoding($false)
$KeepNames = @('www', 'package.json', '_unko_mod')   # ゲームフォルダ直下で触らないもの

#---------------------------------------------------------------------------
# 文言（日本語 / English）
#---------------------------------------------------------------------------
$Text = @{
  ja = @{
    title = 'ウンコテクニカ 非公式MOD（GPU描画＋CANNON修正）'
    intro = "このMODは、ゲームの実行環境（NW.js）を新しい版に入れ替えて、グラフィックボードで描画できるようにします（後半ステージのカクつき対策）。`r`nあわせて、CANNONに飛び込んだ瞬間に向きがズレる不具合を直します。`r`n※ 非公式MODです。自己責任でご利用ください。"
    folder = 'ゲームのフォルダ:'
    browse = '参照...'
    apply = 'MODを適用する'
    revert = '元に戻す'
    close = '閉じる'
    lang = 'Language:'
    st_unknown = '状態: ゲームのフォルダを指定してください'
    st_none = '状態: MODは適用されていません'
    st_ok = '状態: MODは適用済みです（NW.js {0}）'
    st_partial = '状態: MODの一部が元に戻っています（Steamの更新など）。もう一度「MODを適用する」を押してください'
    notfound = 'ウンコテクニカのフォルダが見つかりませんでした。「参照...」から、Game.exe があるフォルダを選んでください。'
    badfolder = 'このフォルダはウンコテクニカのフォルダではないようです（Game.exe と www フォルダがあるフォルダを選んでください）。'
    running = 'ゲームが起動中です。ゲームを終了してから、もう一度押してください。'
    noperm = 'ゲームのフォルダに書き込めませんでした。この画面をいったん閉じて、「UnkoTechnicaMod.bat」を右クリック →「管理者として実行」で開き直してください。'
    nospace = 'ディスクの空き容量が足りません（約1GB必要です）。'
    confirm_apply = "MODを適用します。`r`n`r`n・NW.js（約216MB）を公式サイトからダウンロードします`r`n・元のファイルとセーブデータはバックアップします`r`n・あとで「元に戻す」で元の状態に戻せます`r`n`r`n続けますか？"
    confirm_revert = 'MODを外して、元の状態に戻します。続けますか？'
    s_check = 'ゲームのフォルダを確認しています...'
    s_savebk = 'セーブデータをバックアップしました: {0}'
    s_nosave = 'セーブデータはまだありません（バックアップは不要）'
    s_cache = 'ダウンロード済みのNW.jsを使います'
    s_dl = 'NW.js {0} をダウンロードしています... {1} MB / {2} MB'
    s_verify = 'ダウンロードしたファイルが本物か確認しています（SHA-256）...'
    s_badhash = 'ダウンロードしたファイルが壊れているか、正しいファイルではありません。時間をおいてもう一度試してください。'
    s_dlfail = 'ダウンロードに失敗しました。インターネット接続を確認して、もう一度試してください。'
    s_extract = 'ファイルを展開しています...（少し時間がかかります）'
    s_backup = '元のファイルをバックアップしています...'
    s_copy = '新しい実行環境をコピーしています...'
    s_plugin = 'CANNON修正プラグインを追加しています...'
    s_cleanup = '前回の適用の残りを片付けています...'
    s_already = 'NW.js はすでに入れ替え済みです'
    s_done = '完了しました！いつもどおりSteamからゲームを起動してください。'
    s_rollback = 'エラーが起きたため、元の状態に戻しました。'
    s_error = 'エラーが起きました: {0}'
    s_reverting = '元に戻しています...'
    s_reverted = '元に戻しました。'
    s_notapplied = 'MODは適用されていません。うまく戻らない場合は、Steamで「ゲームファイルの整合性を確認」を実行してください。'
    s_logfile = '記録: {0}'
  }
  en = @{
    title = 'UNKO TECHNICA Unofficial MOD (GPU rendering + CANNON fix)'
    intro = "This MOD replaces the game's runtime (NW.js) with a newer version so the game can render with your graphics card (fixes stutter in later stages).`r`nIt also fixes the bug where a CANNON turns an extra step the moment you enter it.`r`n* Unofficial MOD. Use at your own risk."
    folder = 'Game folder:'
    browse = 'Browse...'
    apply = 'Apply MOD'
    revert = 'Restore original'
    close = 'Close'
    lang = 'Language:'
    st_unknown = 'Status: please select the game folder'
    st_none = 'Status: MOD is not applied'
    st_ok = 'Status: MOD is applied (NW.js {0})'
    st_partial = 'Status: part of the MOD was reverted (e.g. by a Steam update). Press "Apply MOD" again.'
    notfound = 'Could not find the UNKO TECHNICA folder. Use "Browse..." and select the folder that contains Game.exe.'
    badfolder = 'This does not look like the UNKO TECHNICA folder (select the folder that contains Game.exe and the www folder).'
    running = 'The game is running. Please close the game and try again.'
    noperm = 'Could not write to the game folder. Close this window, then right-click "UnkoTechnicaMod.bat" and choose "Run as administrator".'
    nospace = 'Not enough free disk space (about 1 GB is required).'
    confirm_apply = "The MOD will be applied.`r`n`r`n- NW.js (about 216 MB) will be downloaded from the official site`r`n- Your original files and save data will be backed up`r`n- You can undo it later with ""Restore original""`r`n`r`nContinue?"
    confirm_revert = 'Remove the MOD and restore the original files?'
    s_check = 'Checking the game folder...'
    s_savebk = 'Save data backed up to: {0}'
    s_nosave = 'No save data yet (no backup needed)'
    s_cache = 'Using the previously downloaded NW.js'
    s_dl = 'Downloading NW.js {0}... {1} MB / {2} MB'
    s_verify = 'Verifying the downloaded file (SHA-256)...'
    s_badhash = 'The downloaded file is corrupted or not the expected file. Please try again later.'
    s_dlfail = 'Download failed. Please check your internet connection and try again.'
    s_extract = 'Extracting files... (this may take a while)'
    s_backup = 'Backing up the original files...'
    s_copy = 'Copying the new runtime...'
    s_plugin = 'Adding the CANNON fix plugin...'
    s_cleanup = 'Cleaning up leftovers from the previous install...'
    s_already = 'NW.js has already been replaced'
    s_done = 'Done! Start the game from Steam as usual.'
    s_rollback = 'An error occurred, so the original files were restored.'
    s_error = 'An error occurred: {0}'
    s_reverting = 'Restoring the original files...'
    s_reverted = 'The original files have been restored.'
    s_notapplied = 'The MOD is not applied. If something still looks wrong, run "Verify integrity of game files" in Steam.'
    s_logfile = 'Log: {0}'
  }
}
# 表示言語：Windowsの表示言語を直接読む
# （PowerShellのCurrentUICultureは、コンソールの文字コードがUTF-8だと英語に切り替わることがあるため使わない）
function Get-WindowsUiLang {
    try {
        Add-Type -Namespace UnkoMod -Name Kernel32 -MemberDefinition '[DllImport("kernel32.dll")] public static extern ushort GetUserDefaultUILanguage();' -ErrorAction Stop
        return ([System.Globalization.CultureInfo][int][UnkoMod.Kernel32]::GetUserDefaultUILanguage()).Name
    } catch { return [System.Globalization.CultureInfo]::InstalledUICulture.Name }
}
$script:Lang = if ((Get-WindowsUiLang).StartsWith('ja')) { 'ja' } else { 'en' }
function T([string]$key) { return $Text[$script:Lang][$key] }

#---------------------------------------------------------------------------
# 共通処理
#---------------------------------------------------------------------------
New-Item -ItemType Directory -Force -Path $WorkDir | Out-Null

function Log([string]$msg) {
    $line = (Get-Date -Format 'HH:mm:ss') + '  ' + $msg
    if ($Action) { [Console]::Out.WriteLine($line) } else { $script:LogBox.AppendText($line + "`r`n") }
    try { [System.IO.File]::AppendAllText($LogFile, (Get-Date -Format 'yyyy-MM-dd ') + $line + "`r`n", $Utf8) } catch {}
    [System.Windows.Forms.Application]::DoEvents()
}
function SetProgress([int]$v) { $script:Bar.Value = [Math]::Max(0, [Math]::Min(100, $v)); [System.Windows.Forms.Application]::DoEvents() }

# Steamのライブラリからゲームのフォルダを探す
function Find-GameDir {
    $roots = @()
    foreach ($k in @('HKLM:\SOFTWARE\WOW6432Node\Valve\Steam', 'HKLM:\SOFTWARE\Valve\Steam', 'HKCU:\Software\Valve\Steam')) {
        try {
            $p = Get-ItemProperty -Path $k -ErrorAction Stop
            if ($p.SteamPath) { $roots += ($p.SteamPath -replace '/', '\') }
            if ($p.InstallPath) { $roots += $p.InstallPath }
        } catch {}
    }
    $roots += 'C:\Program Files (x86)\Steam'
    $libs = @()
    foreach ($r in ($roots | Select-Object -Unique)) {
        $libs += $r
        $vdf = Join-Path $r 'steamapps\libraryfolders.vdf'
        if (Test-Path -LiteralPath $vdf) {
            foreach ($m in [regex]::Matches((Get-Content -LiteralPath $vdf -Raw), '"path"\s+"([^"]+)"')) {
                $libs += ($m.Groups[1].Value -replace '\\\\', '\')
            }
        }
    }
    foreach ($lib in ($libs | Select-Object -Unique)) {
        $acf = Join-Path $lib ("steamapps\appmanifest_$AppId.acf")
        $dir = 'UNKO TECHNICA'
        if (Test-Path -LiteralPath $acf) {
            $m = [regex]::Match((Get-Content -LiteralPath $acf -Raw), '"installdir"\s+"([^"]+)"')
            if ($m.Success) { $dir = $m.Groups[1].Value }
        }
        $cand = Join-Path $lib ("steamapps\common\" + $dir)
        if (Test-GameDir $cand) { return $cand }
    }
    return $null
}

function Test-GameDir([string]$dir) {
    if (-not $dir -or -not (Test-Path -LiteralPath (Join-Path $dir 'Game.exe'))) { return $false }
    $sys = Join-Path $dir 'www\data\System.json'
    if (-not (Test-Path -LiteralPath $sys) -or -not (Test-Path -LiteralPath (Join-Path $dir 'www\js\plugins.js'))) { return $false }
    try { return ([System.IO.File]::ReadAllText($sys, $Utf8)).Contains('"gameTitle":"' + $GameTitle + '"') } catch { return $false }
}

function Get-Paths([string]$dir) {
    $mod = Join-Path $dir '_unko_mod'
    return @{
        Mod = $mod; Manifest = Join-Path $mod 'installed.txt'; Backup = Join-Path $mod 'runtime_backup'
        PluginsJs = Join-Path $dir 'www\js\plugins.js'; FixDst = Join-Path $dir 'www\js\plugins\CannonPhaseFix.js'
        Save = Join-Path $dir 'www\save'; Exe = Join-Path $dir 'Game.exe'
    }
}

function Get-NwExePath { return (Join-Path (Join-Path $WorkDir $Nw.Folder) 'nw.exe') }

# 状態: none / ok / partial
function Get-ModState([string]$dir) {
    $p = Get-Paths $dir
    if (-not (Test-Path -LiteralPath $p.Manifest)) { return 'none' }
    $nwExe = Get-NwExePath
    $exeOk = (Test-Path -LiteralPath $nwExe) -and ((Get-FileHash -LiteralPath $p.Exe).Hash -eq (Get-FileHash -LiteralPath $nwExe).Hash)
    if (-not $exeOk) {
        # キャッシュが消えていても、マニフェストに記録したハッシュで判定
        $rec = (Get-Content -LiteralPath $p.Manifest -Encoding UTF8 | Where-Object { $_.StartsWith('EXEHASH:') }) -replace '^EXEHASH:', ''
        $exeOk = $rec -and ((Get-FileHash -LiteralPath $p.Exe).Hash -eq $rec)
    }
    $pluginOk = (Test-Path -LiteralPath $p.FixDst) -and ([System.IO.File]::ReadAllText($p.PluginsJs, $Utf8) -match '"name":"CannonPhaseFix"')
    if ($exeOk -and $pluginOk) { return 'ok' }
    return 'partial'
}

function Test-GameRunning([string]$dir) {
    $procs = Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.Path -and $_.Path.StartsWith($dir.TrimEnd('\') + '\', 'OrdinalIgnoreCase') }
    return [bool]$procs
}

function Test-Writable([string]$dir) {
    $t = Join-Path $dir ('_unko_mod_write_test_' + [guid]::NewGuid().ToString('N'))
    try { [System.IO.File]::WriteAllText($t, 'x'); Remove-Item -LiteralPath $t -Force; return $true } catch { return $false }
}

function Get-FreeBytes([string]$path) {
    try { return (New-Object System.IO.DriveInfo ([System.IO.Path]::GetPathRoot($path))).AvailableFreeSpace } catch { return [int64]::MaxValue }
}

#---------------------------------------------------------------------------
# NW.js の取得（ダウンロード → SHA-256確認 → 展開）
#---------------------------------------------------------------------------
function Get-NwRuntime {
    $zip = Join-Path $WorkDir $Nw.File
    $ext = Join-Path $WorkDir $Nw.Folder
    $okFlag = Join-Path $ext '.verified'
    if ((Test-Path -LiteralPath $okFlag) -and (Test-Path -LiteralPath (Join-Path $ext 'nw.exe'))) { Log (T 's_cache'); SetProgress 60; return $ext }

    $haveZip = (Test-Path -LiteralPath $zip) -and ((Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash -eq $Nw.Sha256)
    if (-not $haveZip) {
        $part = $zip + '.part'
        try {
            $req = [System.Net.HttpWebRequest]::Create($Nw.Url)
            $req.UserAgent = 'UnkoTechnicaMod/' + $ModVersion
            $req.Timeout = 30000; $req.ReadWriteTimeout = 60000
            $res = $req.GetResponse()
            $total = $res.ContentLength
            $in = $res.GetResponseStream()
            $out = [System.IO.File]::Create($part)
            $buf = New-Object byte[] 262144
            $done = 0; $lastUi = [DateTime]::MinValue
            while (($n = $in.Read($buf, 0, $buf.Length)) -gt 0) {
                $out.Write($buf, 0, $n); $done += $n
                if (([DateTime]::Now - $lastUi).TotalMilliseconds -gt 200) {
                    $lastUi = [DateTime]::Now
                    $script:StatusLine.Text = [string]::Format((T 's_dl'), $Nw.Version, [int]($done / 1MB), [int]($total / 1MB))
                    if ($total -gt 0) { SetProgress ([int](50 * $done / $total)) } else { [System.Windows.Forms.Application]::DoEvents() }
                }
            }
            $out.Close(); $in.Close(); $res.Close()
        } catch {
            if ($out) { $out.Close() }
            Remove-Item -LiteralPath $part -Force -ErrorAction SilentlyContinue
            throw (T 's_dlfail') + ' (' + $_.Exception.Message + ')'
        }
        Log ([string]::Format((T 's_dl'), $Nw.Version, [int]($done / 1MB), [int]($total / 1MB)))
        Log (T 's_verify')
        $h = (Get-FileHash -LiteralPath $part -Algorithm SHA256).Hash
        if ($h -ne $Nw.Sha256) { Remove-Item -LiteralPath $part -Force; throw (T 's_badhash') }
        Move-Item -LiteralPath $part -Destination $zip -Force
    }
    SetProgress 50
    Log (T 's_extract')
    $tmp = $ext + '.tmp'
    if (Test-Path -LiteralPath $tmp) { Remove-Item -LiteralPath $tmp -Recurse -Force }
    if (Test-Path -LiteralPath $ext) { Remove-Item -LiteralPath $ext -Recurse -Force }
    # 1ファイルずつ展開して、画面が固まらないようにする
    $za = [System.IO.Compression.ZipFile]::OpenRead($zip)
    try {
        $cnt = $za.Entries.Count; $i = 0
        foreach ($en in $za.Entries) {
            $i++
            $target = Join-Path $tmp ($en.FullName -replace '/', '\')
            if ($en.FullName.EndsWith('/')) { New-Item -ItemType Directory -Force -Path $target | Out-Null; continue }
            New-Item -ItemType Directory -Force -Path (Split-Path $target -Parent) | Out-Null
            [System.IO.Compression.ZipFileExtensions]::ExtractToFile($en, $target, $true)
            if ($i % 20 -eq 0) { SetProgress (50 + [int](10 * $i / $cnt)) }
        }
    } finally { $za.Dispose() }
    Move-Item -LiteralPath (Join-Path $tmp $Nw.Folder) -Destination $ext
    Remove-Item -LiteralPath $tmp -Recurse -Force
    [System.IO.File]::WriteAllText($okFlag, $Nw.Sha256)
    SetProgress 60
    return $ext
}

#---------------------------------------------------------------------------
# プラグイン登録 / 解除
#---------------------------------------------------------------------------
function Add-FixPlugin($p) {
    Copy-Item -LiteralPath $FixSrc -Destination $p.FixDst -Force
    $js = [System.IO.File]::ReadAllText($p.PluginsJs, $Utf8)
    if ($js -match '"name":"CannonPhaseFix"') { return }
    $ms = [regex]::Matches($js, '\}(\s*\r?\n\];)')
    if ($ms.Count -eq 0) { throw 'plugins.js format not recognized' }
    $m = $ms[$ms.Count - 1]
    $js = $js.Substring(0, $m.Index) + "},`n" + $FixEntry + $m.Groups[1].Value + $js.Substring($m.Index + $m.Length)
    [System.IO.File]::WriteAllText($p.PluginsJs, $js, $Utf8)
}
function Remove-FixPlugin($p) {
    if (Test-Path -LiteralPath $p.PluginsJs) {
        $js = [System.IO.File]::ReadAllText($p.PluginsJs, $Utf8)
        $js2 = [regex]::Replace($js, ',\r?\n\{"name":"CannonPhaseFix"[^\r\n]*\}', '')
        if ($js2 -ne $js) { [System.IO.File]::WriteAllText($p.PluginsJs, $js2, $Utf8) }
    }
    if (Test-Path -LiteralPath $p.FixDst) { Remove-Item -LiteralPath $p.FixDst -Force }
}

#---------------------------------------------------------------------------
# 実行環境の入れ替え
#---------------------------------------------------------------------------
function Remove-AddedFiles([string]$dir, $p) {
    if (-not (Test-Path -LiteralPath $p.Manifest)) { return }
    foreach ($line in Get-Content -LiteralPath $p.Manifest -Encoding UTF8) {
        if ($line.StartsWith('ADDED:') -or $line.StartsWith('ADDEDDIR:')) {
            $f = Join-Path $dir $line.Substring($line.IndexOf(':') + 1)
            if (Test-Path -LiteralPath $f) { Remove-Item -LiteralPath $f -Recurse -Force }
        }
    }
}

function Restore-Runtime([string]$dir, $p) {
    # バックアップを元の場所へ戻す（同名のものは置き換え）
    if (-not (Test-Path -LiteralPath $p.Backup)) { return }
    Get-ChildItem -LiteralPath $p.Backup -Force | ForEach-Object {
        $dest = Join-Path $dir $_.Name
        if (Test-Path -LiteralPath $dest) { Remove-Item -LiteralPath $dest -Recurse -Force }
        Move-Item -LiteralPath $_.FullName -Destination $dest
    }
}

function Install-Runtime([string]$dir, $p, [string]$src) {
    $nwHash = (Get-FileHash -LiteralPath (Join-Path $src 'nw.exe')).Hash
    if ((Test-Path -LiteralPath $p.Manifest) -and (Get-FileHash -LiteralPath $p.Exe).Hash -eq $nwHash) { Log (T 's_already'); return }

    # 前回の残り（Steamの更新などで一部が元に戻った場合）を片付ける
    if (Test-Path -LiteralPath $p.Manifest) {
        Log (T 's_cleanup')
        Remove-AddedFiles $dir $p
        Remove-Item -LiteralPath $p.Manifest -Force
    }
    if (Test-Path -LiteralPath $p.Backup) { Remove-Item -LiteralPath $p.Backup -Recurse -Force }

    Log (T 's_backup')
    New-Item -ItemType Directory -Force -Path $p.Backup | Out-Null
    $original = @(Get-ChildItem -LiteralPath $dir -Force | Where-Object { $KeepNames -notcontains $_.Name })
    $originalNames = @($original | ForEach-Object { $_.Name })
    $originalFiles = @{}
    $rootLen = $dir.TrimEnd('\').Length + 1
    foreach ($item in $original) {
        if ($item.PSIsContainer) {
            Get-ChildItem -LiteralPath $item.FullName -Recurse -File -Force | ForEach-Object { $originalFiles[$_.FullName.Substring($rootLen).ToLower()] = $true }
        } else { $originalFiles[$item.Name.ToLower()] = $true }
    }
    foreach ($item in $original) { Move-Item -LiteralPath $item.FullName -Destination $p.Backup }
    SetProgress 70

    try {
        Log (T 's_copy')
        $added = @()
        $srcLen = $src.TrimEnd('\').Length + 1
        foreach ($item in (Get-ChildItem -LiteralPath $src -Force | Where-Object { $_.Name -ne '.verified' })) {
            $destName = if ($item.Name -eq 'nw.exe') { 'Game.exe' } else { $item.Name }
            Copy-Item -LiteralPath $item.FullName -Destination (Join-Path $dir $destName) -Recurse -Force
            if ($item.PSIsContainer) {
                if ($originalNames -notcontains $destName) { $added += 'ADDEDDIR:' + $destName }
                else {
                    Get-ChildItem -LiteralPath $item.FullName -Recurse -File -Force | ForEach-Object {
                        $rel = $_.FullName.Substring($srcLen)
                        if (-not $originalFiles.ContainsKey($rel.ToLower())) { $added += 'ADDED:' + $rel }
                    }
                }
            } elseif (-not $originalFiles.ContainsKey($destName.ToLower())) { $added += 'ADDED:' + $destName }
            [System.Windows.Forms.Application]::DoEvents()
        }
        $lines = @('UNKO TECHNICA unofficial MOD ' + $ModVersion, 'NWJS:' + $Nw.Version, 'EXEHASH:' + $nwHash,
                   'DATE:' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')) + $added
        [System.IO.File]::WriteAllLines($p.Manifest, [string[]]$lines, $Utf8)
    } catch {
        # 失敗したら元に戻す
        Get-ChildItem -LiteralPath $dir -Force | Where-Object { $KeepNames -notcontains $_.Name } | Remove-Item -Recurse -Force
        Restore-Runtime $dir $p
        Remove-Item -LiteralPath $p.Backup -Recurse -Force -ErrorAction SilentlyContinue
        Log (T 's_rollback')
        throw
    }
    SetProgress 90
}

#---------------------------------------------------------------------------
# 適用 / 元に戻す
#---------------------------------------------------------------------------
function Backup-Saves($p) {
    if (-not (Test-Path -LiteralPath $p.Save) -or -not (Get-ChildItem -LiteralPath $p.Save -Force)) { Log (T 's_nosave'); return }
    $dst = Join-Path $SaveBkDir ('save_' + (Get-Date -Format 'yyyyMMdd_HHmmss'))
    New-Item -ItemType Directory -Force -Path $SaveBkDir | Out-Null
    Copy-Item -LiteralPath $p.Save -Destination $dst -Recurse -Force
    Log ([string]::Format((T 's_savebk'), $dst))
}

function Precheck([string]$dir) {
    if (-not (Test-GameDir $dir)) { throw (T 'badfolder') }
    if (Test-GameRunning $dir) { throw (T 'running') }
    if (-not (Test-Writable $dir)) { throw (T 'noperm') }
}

function Invoke-Apply {
    $dir = $script:FolderBox.Text.Trim()
    try {
        Log (T 's_check'); SetProgress 0
        Precheck $dir
        if ((Get-FreeBytes $dir) -lt 1GB -or (Get-FreeBytes $WorkDir) -lt 700MB) { throw (T 'nospace') }
        $p = Get-Paths $dir
        Backup-Saves $p
        $src = Get-NwRuntime
        Install-Runtime $dir $p $src
        Log (T 's_plugin'); Add-FixPlugin $p
        SetProgress 100
        Log (T 's_done')
        Show-Msg (T 's_done') $false
    } catch {
        $msg = $_.Exception.Message
        Log ([string]::Format((T 's_error'), $msg))
        Show-Msg $msg $true
    }
    Update-Status
}

function Show-Msg([string]$msg, [bool]$warn) {
    if ($Action) { if ($warn) { $script:ExitCode = 1 }; return }
    if ($warn) { [System.Windows.Forms.MessageBox]::Show($msg, (T 'title'), 'OK', 'Warning') | Out-Null }
    else { [System.Windows.Forms.MessageBox]::Show($msg, (T 'title')) | Out-Null }
}

function Invoke-Revert {
    $dir = $script:FolderBox.Text.Trim()
    try {
        Precheck $dir
        $p = Get-Paths $dir
        if (-not (Test-Path -LiteralPath $p.Manifest)) {
            Remove-FixPlugin $p
            Log (T 's_notapplied')
            Show-Msg (T 's_notapplied') $false
            Update-Status; return
        }
        Log (T 's_reverting'); SetProgress 10
        Remove-AddedFiles $dir $p; SetProgress 40
        Restore-Runtime $dir $p; SetProgress 80
        Remove-FixPlugin $p
        Remove-Item -LiteralPath $p.Mod -Recurse -Force
        SetProgress 100
        Log (T 's_reverted')
        Show-Msg (T 's_reverted') $false
    } catch {
        $msg = $_.Exception.Message
        Log ([string]::Format((T 's_error'), $msg))
        Show-Msg $msg $true
    }
    Update-Status
}

#---------------------------------------------------------------------------
# 画面
#---------------------------------------------------------------------------
$form = New-Object System.Windows.Forms.Form
$form.Size = New-Object System.Drawing.Size(640, 520)
$form.StartPosition = 'CenterScreen'
$form.FormBorderStyle = 'FixedDialog'
$form.MaximizeBox = $false
$form.Font = New-Object System.Drawing.Font('Yu Gothic UI', 9)

function NewCtl($type, $x, $y, $w, $h) {
    $c = New-Object $type
    $c.Location = New-Object System.Drawing.Point($x, $y)
    $c.Size = New-Object System.Drawing.Size($w, $h)
    $form.Controls.Add($c); return $c
}
$introLbl  = NewCtl System.Windows.Forms.Label 15 12 600 70
$langLbl   = NewCtl System.Windows.Forms.Label 420 88 70 22
$langBox   = NewCtl System.Windows.Forms.ComboBox 490 85 120 24
$langBox.DropDownStyle = 'DropDownList'; [void]$langBox.Items.Add('日本語'); [void]$langBox.Items.Add('English')
$folderLbl = NewCtl System.Windows.Forms.Label 15 118 600 20
$script:FolderBox = NewCtl System.Windows.Forms.TextBox 15 140 500 24
$browseBtn = NewCtl System.Windows.Forms.Button 525 139 85 26
$statusLbl = NewCtl System.Windows.Forms.Label 15 172 600 36
$statusLbl.Font = New-Object System.Drawing.Font('Yu Gothic UI', 9, [System.Drawing.FontStyle]::Bold)
$applyBtn  = NewCtl System.Windows.Forms.Button 15 212 190 36
$revertBtn = NewCtl System.Windows.Forms.Button 215 212 190 36
$closeBtn  = NewCtl System.Windows.Forms.Button 520 212 90 36
$script:Bar = NewCtl System.Windows.Forms.ProgressBar 15 258 595 18
$script:StatusLine = NewCtl System.Windows.Forms.Label 15 280 595 20
$script:LogBox = NewCtl System.Windows.Forms.TextBox 15 302 595 165
$script:LogBox.Multiline = $true; $script:LogBox.ReadOnly = $true; $script:LogBox.ScrollBars = 'Vertical'

function Apply-Texts {
    $form.Text = (T 'title') + '  v' + $ModVersion
    $introLbl.Text = T 'intro'; $langLbl.Text = T 'lang'; $folderLbl.Text = T 'folder'
    $browseBtn.Text = T 'browse'; $applyBtn.Text = T 'apply'; $revertBtn.Text = T 'revert'; $closeBtn.Text = T 'close'
    Update-Status
}
function Update-Status {
    $dir = $script:FolderBox.Text.Trim()
    $ok = Test-GameDir $dir
    $applyBtn.Enabled = $ok; $revertBtn.Enabled = $ok
    if (-not $ok) { $statusLbl.Text = T 'st_unknown'; $statusLbl.ForeColor = 'DimGray'; return }
    switch (Get-ModState $dir) {
        'ok'      { $statusLbl.Text = [string]::Format((T 'st_ok'), $Nw.Version); $statusLbl.ForeColor = 'DarkGreen' }
        'partial' { $statusLbl.Text = T 'st_partial'; $statusLbl.ForeColor = 'DarkOrange' }
        default   { $statusLbl.Text = T 'st_none'; $statusLbl.ForeColor = 'Black' }
    }
}
function Set-Busy([bool]$b) {
    foreach ($c in @($applyBtn, $revertBtn, $closeBtn, $browseBtn, $langBox, $script:FolderBox)) { $c.Enabled = -not $b }
    $form.UseWaitCursor = $b
}

$langBox.Add_SelectedIndexChanged({
    # 画面の準備中に一瞬「未選択(-1)」になることがあるので無視する（-1だと配列の最後=英語になってしまう）
    if ($langBox.SelectedIndex -lt 0) { return }
    $script:Lang = @('ja', 'en')[$langBox.SelectedIndex]; Apply-Texts
})
$browseBtn.Add_Click({
    $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
    $dlg.Description = T 'folder'
    if ($dlg.ShowDialog() -eq 'OK') { $script:FolderBox.Text = $dlg.SelectedPath; Update-Status }
})
$script:FolderBox.Add_Leave({ Update-Status })
$applyBtn.Add_Click({
    if ([System.Windows.Forms.MessageBox]::Show((T 'confirm_apply'), (T 'title'), 'YesNo', 'Question') -ne 'Yes') { return }
    Set-Busy $true; try { Invoke-Apply } finally { Set-Busy $false; Update-Status }
})
$revertBtn.Add_Click({
    if ([System.Windows.Forms.MessageBox]::Show((T 'confirm_revert'), (T 'title'), 'YesNo', 'Question') -ne 'Yes') { return }
    Set-Busy $true; try { Invoke-Revert } finally { Set-Busy $false; Update-Status }
})
$closeBtn.Add_Click({ $form.Close() })

$form.Add_Shown({
    $found = Find-GameDir
    if ($found) { $script:FolderBox.Text = $found } else { Log (T 'notfound') }
    Update-Status
    Log ([string]::Format((T 's_logfile'), $LogFile))
})

$langBox.SelectedIndex = if ($script:Lang -eq 'ja') { 0 } else { 1 }
Apply-Texts

if ($Action) {
    # 画面なしで実行（動作確認・サポート用）
    $oldEnc = [Console]::OutputEncoding
    [Console]::OutputEncoding = $Utf8
    $script:ExitCode = 0
    $script:FolderBox.Text = if ($GameDir) { $GameDir } else { [string](Find-GameDir) }
    Update-Status
    Log ('GameDir: ' + $script:FolderBox.Text)
    switch ($Action) {
        'apply'    { Invoke-Apply }
        'revert'   { Invoke-Revert }
        'download' { try { Log ('Runtime: ' + (Get-NwRuntime)) } catch { Log ([string]::Format((T 's_error'), $_.Exception.Message)); $script:ExitCode = 1 } }
    }
    Log ($statusLbl.Text)
    [Console]::OutputEncoding = $oldEnc
    exit $script:ExitCode
}
[void]$form.ShowDialog()
