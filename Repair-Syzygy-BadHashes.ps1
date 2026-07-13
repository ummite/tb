#Requires -Version 5.1
# Repair Syzygy files whose embedded CityHash != official checksums.
# Prefer local good copy; else download from tablebase.sesse.net with curl resume.
# Idempotent: safe after power loss. See RESUME_AFTER_OUTAGE.md

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$Root = 'T:\Syzygy',
    [string]$ChecksumDir = '',
    [string]$PlanCsv = '',
    [string]$LogDir = '',
    [string[]]$LocalSearchRoots = @(
        'A:\Syzygy',
        'A:\Syzygy_A_Trier_FromOld_Ryzen7950\Syzygy',
        'S:\Syzygy',
        'C:\Programmation\tb-1\Syzygy'
    ),
    [string]$SesseBase = 'http://tablebase.sesse.net/syzygy',
    [switch]$LocalOnly,
    [switch]$DownloadOnly,
    [double]$MaxDownloadMB = 0,
    [switch]$Rescan
)

$ErrorActionPreference = 'Stop'
$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
if (-not $ChecksumDir) { $ChecksumDir = Join-Path $ScriptDir 'checksums' }
if (-not $PlanCsv) { $PlanCsv = Join-Path $ScriptDir 'logs\syzygy-bad-hash-repair-plan.csv' }
if (-not $LogDir) { $LogDir = Join-Path $ScriptDir 'logs' }
if (-not (Test-Path -LiteralPath $LogDir)) { New-Item -ItemType Directory -Path $LogDir | Out-Null }

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$log = Join-Path $LogDir ("syzygy-repair-{0}.log" -f $stamp)
$reportOut = Join-Path $LogDir ("syzygy-repair-results-{0}.csv" -f $stamp)

function Write-Log {
    param([string]$Msg, [ConsoleColor]$Color = 'Gray')
    $line = '{0}  {1}' -f (Get-Date -Format 'HH:mm:ss'), $Msg
    Write-Host $line -ForegroundColor $Color
    Add-Content -LiteralPath $log -Value $line
}

function Get-EmbeddedCityHash {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return $null }
    $fs = [System.IO.File]::Open($Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
    try {
        $len = $fs.Length
        if ($len -lt 16) { return $null }
        if (($len -band 0x3f) -ne 0x10) { return $null }
        $null = $fs.Seek($len - 16, [System.IO.SeekOrigin]::Begin)
        $buf = New-Object byte[] 16
        if ($fs.Read($buf, 0, 16) -ne 16) { return $null }
        return (-join ($buf | ForEach-Object { $_.ToString('x2') }))
    } finally {
        $fs.Dispose()
    }
}

function Get-PieceCount {
    param([string]$FileName)
    $b = [IO.Path]::GetFileNameWithoutExtension($FileName)
    return ($b -replace 'v', '').Length
}

function Get-SesseUrl {
    param([string]$FileName)
    $ext = [IO.Path]::GetExtension($FileName).ToLowerInvariant()
    $pcs = Get-PieceCount -FileName $FileName
    if ($pcs -le 5) {
        $folder = '3-4-5'
    } elseif ($pcs -eq 6) {
        if ($ext -eq '.rtbw') { $folder = '6-WDL' } else { $folder = '6-DTZ' }
    } else {
        if ($ext -eq '.rtbw') { $folder = '7-WDL' } else { $folder = '7-DTZ' }
    }
    return ('{0}/{1}/{2}' -f $SesseBase, $folder, $FileName)
}

function Test-OfficialHash {
    param([string]$Path, [string]$Expected)
    $emb = Get-EmbeddedCityHash -Path $Path
    return ($emb -and $Expected -and ($emb -eq $Expected))
}

function Copy-Verified {
    param([string]$Source, [string]$Dest, [string]$ExpectedHash, [string]$Name)
    $tmp = $Dest + '.repair-tmp'
    if (Test-Path -LiteralPath $tmp) { Remove-Item -LiteralPath $tmp -Force }
    Write-Log ('  COPY  {0}' -f $Source)
    Write-Log ('    ->  {0}' -f $tmp)
    Copy-Item -LiteralPath $Source -Destination $tmp -Force
    if (-not (Test-OfficialHash -Path $tmp -Expected $ExpectedHash)) {
        $got = Get-EmbeddedCityHash -Path $tmp
        Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue
        throw ('Hash mismatch after local copy of {0} (got {1} expected {2})' -f $Name, $got, $ExpectedHash)
    }
    if (Test-Path -LiteralPath $Dest) { Remove-Item -LiteralPath $Dest -Force }
    Move-Item -LiteralPath $tmp -Destination $Dest -Force
    Write-Log ('  OK    local repair {0}' -f $Name) Green
}

function Download-Verified {
    param([string]$Url, [string]$Dest, [string]$ExpectedHash, [string]$Name)
    $tmp = $Dest + '.repair-part'
    if (Test-Path -LiteralPath $tmp) {
        $partLen = (Get-Item -LiteralPath $tmp).Length
        $ageMin = ([DateTime]::Now - (Get-Item -LiteralPath $tmp).LastWriteTime).TotalMinutes
        if ($partLen -lt 1MB -and $ageMin -gt 15) {
            Write-Log ('  DROP  stale tiny partial ({0} bytes)' -f $partLen)
            Remove-Item -LiteralPath $tmp -Force
        } else {
            Write-Log ('  RESUME partial {0:N1} MB' -f ($partLen / 1MB))
        }
    }
    Write-Log ('  GET   {0}' -f $Url)
    Write-Log ('    ->  {0}' -f $tmp)

    $curl = Join-Path $env:SystemRoot 'System32\curl.exe'
    if (-not (Test-Path -LiteralPath $curl)) {
        $cmd = Get-Command curl.exe -ErrorAction SilentlyContinue
        if ($cmd) { $curl = $cmd.Source } else { throw 'curl.exe not found' }
    }

    $curlArgs = @(
        '-L', '--fail', '--retry', '20', '--retry-delay', '10', '--retry-all-errors',
        '--connect-timeout', '60',
        '-C', '-',
        '--output', $tmp,
        $Url
    )
    Write-Log ('  curl starting...')
    & $curl @curlArgs
    $code = $LASTEXITCODE
    if ($code -eq 33) {
        Write-Log '  curl exit 33 (range) - full re-download'
        Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue
        $curlArgs2 = @(
            '-L', '--fail', '--retry', '20', '--retry-delay', '10', '--retry-all-errors',
            '--connect-timeout', '60',
            '--output', $tmp,
            $Url
        )
        & $curl @curlArgs2
        $code = $LASTEXITCODE
    }
    if ($code -ne 0) { throw ('curl exit {0} for {1}' -f $code, $Name) }
    if (-not (Test-Path -LiteralPath $tmp) -or ((Get-Item -LiteralPath $tmp).Length -lt 64)) {
        throw ('Download empty/missing for {0}' -f $Name)
    }
    Write-Log ('  GOT   {0:N1} MB' -f ((Get-Item -LiteralPath $tmp).Length / 1MB))

    if (-not (Test-OfficialHash -Path $tmp -Expected $ExpectedHash)) {
        $got = Get-EmbeddedCityHash -Path $tmp
        throw ('Hash mismatch after download of {0} (got {1} expected {2})' -f $Name, $got, $ExpectedHash)
    }
    if (Test-Path -LiteralPath $Dest) { Remove-Item -LiteralPath $Dest -Force }
    Move-Item -LiteralPath $tmp -Destination $Dest -Force
    Write-Log ('  OK    download repair {0}' -f $Name) Green
}

# Load official hashes
$official = @{}
Get-ChildItem -LiteralPath $ChecksumDir -Filter '*.txt' | ForEach-Object {
    Get-Content -LiteralPath $_.FullName | ForEach-Object {
        if ($_ -match '^([^:]+):\s*([0-9a-fA-F]{32})\s*$') {
            $official[$matches[1]] = $matches[2].ToLowerInvariant()
        }
    }
}
Write-Log ('Official checksum entries: {0}' -f $official.Count)
Write-Log ('Root: {0}' -f $Root)
Write-Log ('Log:  {0}' -f $log)

$jobs = New-Object System.Collections.Generic.List[object]

if ($Rescan -or -not (Test-Path -LiteralPath $PlanCsv)) {
    Write-Log ('Scanning {0} for official mismatches...' -f $Root)
    Get-ChildItem -LiteralPath $Root -Recurse -File -ErrorAction SilentlyContinue |
        Where-Object {
            $_.Extension -in '.rtbw', '.rtbz' -and
            $_.FullName -notmatch '\\(agent-tools|terminals|logs)\\' -and
            $official.ContainsKey($_.Name)
        } |
        ForEach-Object {
            $exp = $official[$_.Name]
            if (-not (Test-OfficialHash -Path $_.FullName -Expected $exp)) {
                [void]$jobs.Add([PSCustomObject]@{
                    Name = $_.Name
                    Dest = $_.FullName
                    OfficialHash = $exp
                    Source = ''
                })
            }
        }
} else {
    Write-Log ('Loading plan: {0}' -f $PlanCsv)
    Import-Csv -LiteralPath $PlanCsv | ForEach-Object {
        if ($_.T_OK -eq 'True') { return }
        [void]$jobs.Add([PSCustomObject]@{
            Name = $_.Name
            Dest = $_.Dest
            OfficialHash = $official[$_.Name]
            Source = $_.Source
        })
    }
}

foreach ($j in $jobs) {
    if ($j.Source -and (Test-Path -LiteralPath $j.Source) -and
        (Test-OfficialHash -Path $j.Source -Expected $j.OfficialHash)) {
        continue
    }
    $j.Source = ''
    foreach ($searchRoot in $LocalSearchRoots) {
        if (-not (Test-Path -LiteralPath $searchRoot)) { continue }
        $hit = Get-ChildItem -LiteralPath $searchRoot -Recurse -Filter $j.Name -File -ErrorAction SilentlyContinue |
            Where-Object { Test-OfficialHash -Path $_.FullName -Expected $j.OfficialHash } |
            Select-Object -First 1
        if ($hit) {
            $j.Source = $hit.FullName
            break
        }
    }
}

Write-Log ('Work items: {0}' -f $jobs.Count)
$withLocal = @($jobs | Where-Object { $_.Source }).Count
Write-Log ('  Local good source: {0}' -f $withLocal)
Write-Log ('  Need download:     {0}' -f ($jobs.Count - $withLocal))

$jobs = @(
    $jobs | Sort-Object `
        @{ Expression = { if ($_.Source) { 0 } else { 1 } } }, `
        @{ Expression = {
            if (Test-Path -LiteralPath $_.Dest) { (Get-Item -LiteralPath $_.Dest).Length }
            else { [int64]::MaxValue }
        } }
)

$results = New-Object System.Collections.Generic.List[object]
$downloadedMB = 0.0

foreach ($j in $jobs) {
    $name = $j.Name
    $dest = $j.Dest
    $exp = $j.OfficialHash
    $status = 'FAILED'
    $method = ''

    if (-not $exp) {
        Write-Log ('SKIP {0} (no official hash)' -f $name) Yellow
        [void]$results.Add([PSCustomObject]@{ Name = $name; Status = 'NO_OFFICIAL'; Method = '' })
        continue
    }

    if ((Test-Path -LiteralPath $dest) -and (Test-OfficialHash -Path $dest -Expected $exp)) {
        Write-Log ('SKIP {0} (already OK)' -f $name) DarkGray
        [void]$results.Add([PSCustomObject]@{ Name = $name; Status = 'ALREADY_OK'; Method = '' })
        continue
    }

    try {
        if (-not $DownloadOnly -and $j.Source) {
            if ($PSCmdlet.ShouldProcess($dest, ('Repair from local {0}' -f $j.Source))) {
                Copy-Verified -Source $j.Source -Dest $dest -ExpectedHash $exp -Name $name
            }
            $status = 'REPAIRED'
            $method = 'local'
        } elseif (-not $LocalOnly) {
            $url = Get-SesseUrl -FileName $name
            $sizeMB = 0.0
            try {
                $req = [System.Net.HttpWebRequest]::Create($url)
                $req.Method = 'HEAD'
                $req.Timeout = 30000
                $resp = $req.GetResponse()
                $sizeMB = [math]::Round($resp.ContentLength / 1MB, 2)
                $resp.Close()
            } catch {
                throw ('HEAD failed for {0} : {1}' -f $url, $_.Exception.Message)
            }

            if ($MaxDownloadMB -gt 0 -and (($downloadedMB + $sizeMB) -gt $MaxDownloadMB)) {
                Write-Log ('SKIP {0} ({1} MB) - budget exhausted' -f $name, $sizeMB) Yellow
                $status = 'SKIPPED_BUDGET'
                $method = 'download'
            } else {
                $msg = 'Download {0} MB from {1}' -f $sizeMB, $url
                if ($PSCmdlet.ShouldProcess($dest, $msg)) {
                    $dir = Split-Path -Parent $dest
                    if (-not (Test-Path -LiteralPath $dir)) {
                        New-Item -ItemType Directory -Path $dir -Force | Out-Null
                    }
                    Download-Verified -Url $url -Dest $dest -ExpectedHash $exp -Name $name
                    $downloadedMB += $sizeMB
                }
                $status = 'REPAIRED'
                $method = ('download:{0} MB' -f $sizeMB)
            }
        } else {
            Write-Log ('SKIP {0} (no local source, LocalOnly)' -f $name) Yellow
            $status = 'NEED_DOWNLOAD'
            $method = ''
        }
    } catch {
        Write-Log ('FAIL {0} : {1}' -f $name, $_.Exception.Message) Red
        $status = 'FAILED'
        $method = $_.Exception.Message
    }

    [void]$results.Add([PSCustomObject]@{
        Name   = $name
        Dest   = $dest
        Status = $status
        Method = $method
    })
}

$results | Export-Csv -LiteralPath $reportOut -NoTypeInformation -Encoding UTF8

Write-Log ''
Write-Log '=== SUMMARY ===' Cyan
$results | Group-Object Status | ForEach-Object {
    Write-Log ('  {0}: {1}' -f $_.Name, $_.Count)
}
Write-Log ('Downloaded this run: {0} MB' -f ([math]::Round($downloadedMB, 1)))
Write-Log ('Results: {0}' -f $reportOut)
Write-Log ('Log:     {0}' -f $log)

$failed = @($results | Where-Object Status -eq 'FAILED').Count
$needDlLeft = @($results | Where-Object Status -in 'NEED_DOWNLOAD', 'SKIPPED_BUDGET').Count
if ($failed -gt 0) { exit 2 }
if ($needDlLeft -gt 0) { exit 1 }
exit 0
