<#
.SYNOPSIS
    Pull official Stockfish git, compile with max local optimizations (PGO),
    and install the exe used by Syzygy 7/8 probe tests.

.DESCRIPTION
    Clone lives at StockfishSrc\ (gitignored, own .git, origin = official-stockfish).
    Output:
      bin\stockfish.exe       official probe limit (7-piece)
      bin\stockfish-tb8.exe   only with -Enable8Piece (TBPIECES=8 local patch)

    Best flags on this machine (i9-13900KF): ARCH=x86-64-avxvnni, profile-build (PGO).
    Toolchain: scoop mingw (GCC 15+). Ancient C:\MinGW 6.3 cannot compile modern Stockfish.
    LLVM clang here is the MSVC target and is not used (Makefile expects MinGW).

.EXAMPLE
    .\Build-Stockfish.ps1 -InstallToolchain
    .\Build-Stockfish.ps1 -Enable8Piece
    .\Build-Stockfish.ps1 -SkipPull
#>
param(
    [switch]$InstallToolchain,
    [switch]$Enable8Piece,
    [switch]$SkipPull,
    [switch]$Pgo,
    [switch]$NoPgo,
    [ValidateSet("auto", "x86-64-avxvnni", "x86-64-bmi2", "x86-64-avx2", "native")]
    [string]$Arch = "auto",
    [int]$Jobs = 0
)

$ErrorActionPreference = "Stop"
$Root = $PSScriptRoot
$SrcDir = Join-Path $Root "StockfishSrc"
$SrcMakeDir = Join-Path $SrcDir "src"
$BinDir = Join-Path $Root "bin"
$Git = "https://github.com/official-stockfish/Stockfish.git"
$Bash = "C:\Program Files\Git\bin\bash.exe"
$Out7 = Join-Path $BinDir "stockfish.exe"
$Out8 = Join-Path $BinDir "stockfish-tb8.exe"

function Write-Step([string]$Msg) {
    Write-Host ""
    Write-Host "=== $Msg ===" -ForegroundColor Cyan
}

function Get-ScoopMingwBin {
    $candidates = @(
        (Join-Path $env:USERPROFILE "scoop\apps\mingw\current\bin"),
        (Join-Path $env:USERPROFILE "scoop\apps\gcc\current\bin")
    )
    foreach ($d in $candidates) {
        $gpp = Join-Path $d "g++.exe"
        if (Test-Path -LiteralPath $gpp) {
            $ver = & $gpp --version 2>$null | Select-Object -First 1
            if ($ver -match '(\d+)\.') {
                $major = [int]$Matches[1]
                if ($major -ge 12) { return $d }
            }
        }
    }
    return $null
}

function ConvertTo-MsysPath([string]$WinPath) {
    $full = [System.IO.Path]::GetFullPath($WinPath)
    $full = $full -replace '\\', '/'
    if ($full -match '^([A-Za-z]):(.*)$') {
        return "/$($Matches[1].ToLower())$($Matches[2])"
    }
    return $full
}

if (-not (Test-Path -LiteralPath $Bash)) {
    throw "Git Bash introuvable ($Bash). Requis pour le Makefile Stockfish."
}

Write-Step "1/6  Clone / update StockfishSrc"
if (-not (Test-Path -LiteralPath (Join-Path $SrcDir ".git"))) {
    if (Test-Path -LiteralPath $SrcDir) {
        throw "StockfishSrc existe sans .git. Clonez : git clone $Git StockfishSrc"
    }
    git clone --depth 1 $Git $SrcDir
}
elseif (-not $SkipPull) {
    git -C $SrcDir fetch --tags origin
    git -C $SrcDir pull --ff-only origin master
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "git pull a echoue (arbre sale ?). Build du HEAD actuel."
        git -C $SrcDir status -sb
    }
}
else {
    Write-Host "SkipPull : HEAD local conserve."
}
git -C $SrcDir log -1 --oneline
git -C $SrcDir rev-parse --abbrev-ref HEAD

Write-Step "2/6  Toolchain MinGW-w64 (GCC 12+)"
$mingwBin = Get-ScoopMingwBin
if (-not $mingwBin) {
    if (-not $InstallToolchain) {
        throw "Aucun GCC moderne (12+) trouve. Lancez : scoop install mingw   puis   .\Build-Stockfish.ps1   ou   .\Build-Stockfish.ps1 -InstallToolchain"
    }
    if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
        throw "scoop n'est pas dans le PATH. Installez scoop, puis : scoop install mingw"
    }
    Write-Host "Installation scoop mingw..." -ForegroundColor Yellow
    scoop install mingw
    $mingwBin = Get-ScoopMingwBin
    if (-not $mingwBin) { throw "scoop mingw installe mais g++.exe introuvable." }
}
$gpp = Join-Path $mingwBin "g++.exe"
Write-Host "g++ : $gpp"
& $gpp --version | Select-Object -First 1

Write-Step "3/6  ARCH"
if ($Arch -eq "auto") {
    $cpu = (Get-CimInstance Win32_Processor).Name
    Write-Host "CPU : $cpu"
    if ($cpu -match '13900|14900|14700|13700|13600|14600|i9-13|i7-13|i5-13|i9-14|i7-14') {
        $Arch = "x86-64-avxvnni"
    }
    else {
        $Arch = "x86-64-avx2"
    }
}
$usePgo = $Pgo -and -not $NoPgo
$pgoLabel = if ($usePgo) { "on" } else { "off" }
Write-Host "ARCH=$Arch  PGO=$pgoLabel"
if (-not $usePgo) {
    Write-Host "PGO desactive par defaut (bench instrumente crash sous MinGW, exit 139). Pour tenter : -Pgo"
}

if ($Jobs -le 0) {
    $Jobs = [Math]::Max(1, [int]$env:NUMBER_OF_PROCESSORS)
}
$target = if ($usePgo) { "profile-build" } else { "build" }
Write-Host "make -j $Jobs $target ARCH=$Arch COMP=gcc"

function Invoke-StockfishMake {
    param(
        [string]$DestExe,
        [switch]$Tb8
    )

    $tbprobe = Join-Path $SrcMakeDir "syzygy\tbprobe.cpp"
    $patched = $false
    if ($Tb8) {
        $orig = [System.Text.Encoding]::UTF8.GetString([System.IO.File]::ReadAllBytes($tbprobe))
        if ($orig -notmatch 'constexpr int TBPIECES = 7;') {
            throw "Marqueur TBPIECES=7 introuvable dans tbprobe.cpp (source Stockfish change, patch 8pc a revoir)."
        }
        $new = $orig.Replace('constexpr int TBPIECES = 7;', 'constexpr int TBPIECES = 8;')
        [System.IO.File]::WriteAllBytes($tbprobe, [System.Text.Encoding]::UTF8.GetBytes($new))
        $patched = $true
        Write-Host "Patch local TBPIECES=7 -> 8 (restaure apres le build)" -ForegroundColor Yellow
    }

    $msysSrc = ConvertTo-MsysPath $SrcMakeDir
    $msysMingw = ConvertTo-MsysPath $mingwBin
    $script = @'
set -euo pipefail
export PATH="__MINGW__:/usr/bin:/bin:$PATH"
hash -r
echo "g++ used: $(which g++)"
g++ --version | head -n 1
cd "__SRC__"
make clean
make -j __JOBS__ __TARGET__ ARCH=__ARCH__ COMP=gcc
ls -l stockfish.exe
'@
    $script = $script.Replace('__MINGW__', $msysMingw).Replace('__SRC__', $msysSrc).Replace('__JOBS__', "$Jobs").Replace('__TARGET__', $target).Replace('__ARCH__', $Arch)
    $script = $script -replace "`r`n", "`n"
    $shFile = Join-Path $env:TEMP "build-stockfish.sh"
    $utf8 = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($shFile, $script, $utf8)
    $shMsys = ConvertTo-MsysPath $shFile

    try {
        & $Bash $shMsys
        if ($LASTEXITCODE -ne 0) {
            if ($target -eq "profile-build") {
                Write-Warning "profile-build a echoue (souvent un crash du bench instrumente sous MinGW). Fallback : make build (-O3 -flto)."
                $scriptFb = $script.Replace("profile-build", "build")
                [System.IO.File]::WriteAllText($shFile, $scriptFb, $utf8)
                & $Bash $shMsys
            }
            if ($LASTEXITCODE -ne 0) {
                throw "make a echoue (exit $LASTEXITCODE)"
            }
        }
        $built = Join-Path $SrcMakeDir "stockfish.exe"
        if (-not (Test-Path -LiteralPath $built)) {
            throw "stockfish.exe absent apres make : $built"
        }
        New-Item -ItemType Directory -Force -Path $BinDir | Out-Null
        Copy-Item -LiteralPath $built -Destination $DestExe -Force
        Write-Host "Installe : $DestExe" -ForegroundColor Green
    }
    finally {
        if ($patched) {
            git -C $SrcDir checkout -- "src/syzygy/tbprobe.cpp"
            Write-Host "Source tbprobe.cpp restaure (git checkout)." -ForegroundColor DarkGray
        }
    }
}

Write-Step "4/6  Build officiel (TBPIECES=7) -> bin\stockfish.exe"
Invoke-StockfishMake -DestExe $Out7

if ($Enable8Piece) {
    Write-Step "5/6  Build 8pc (TBPIECES=8 patch) -> bin\stockfish-tb8.exe"
    Invoke-StockfishMake -DestExe $Out8 -Tb8
}
else {
    Write-Step "5/6  Skip 8pc"
    Write-Host "Pour le probing 8-piece : .\Build-Stockfish.ps1 -Enable8Piece"
}

Write-Step "6/6  Identite UCI"
foreach ($exe in @($Out7, $Out8)) {
    if (-not (Test-Path -LiteralPath $exe)) { continue }
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $exe
    $psi.RedirectStandardInput = $true
    $psi.RedirectStandardOutput = $true
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $proc = [System.Diagnostics.Process]::Start($psi)
    $proc.StandardInput.WriteLine("uci")
    $proc.StandardInput.WriteLine("quit")
    $proc.StandardInput.Close()
    $out = $proc.StandardOutput.ReadToEnd()
    $proc.WaitForExit()
    $id = $out -split "`r?`n" | Where-Object { $_ -match '^id (name|author) ' }
    Write-Host ""
    Write-Host $exe -ForegroundColor Green
    $id | ForEach-Object { Write-Host "  $_" }
    $fi = Get-Item $exe
    Write-Host "  size=$($fi.Length)  mtime=$($fi.LastWriteTime)"
}

Write-Host ""
Write-Host "Termine." -ForegroundColor Cyan
Write-Host "  7pc tests : .\Test-Stockfish-Syzygy.ps1"
Write-Host "              .\Test-Syzygy-Probe-Immediate.ps1"
Write-Host "  8pc tests : .\Test-Syzygy-Probe-Immediate.ps1 -Need8Piece"
Write-Host "  Rebuild   : .\Build-Stockfish.ps1 -Enable8Piece"
Write-Host "tbcheck/rtbver restent la verification de format ; Stockfish sert au probing moteur."
