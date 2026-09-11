# Build-Manifest.ps1
# Builds C:\Programmation\tb-1\verification\expected-manifest.csv from the 6 checksum files
# in C:\Programmation\tb-1\checksums\ (wdl345/dtz345/wdl6/dtz6/wdl7/dtz7 = 3022 entries).
# PowerShell 5.1 compatible: no ??, no ?., no ForEach-Object -Parallel.
# Exit: 0 if the manifest is complete (3022 entries), 1 otherwise.

$ErrorActionPreference = 'Stop'

$checksumDir = 'C:\Programmation\tb-1\checksums'
$outPath = 'C:\Programmation\tb-1\verification\expected-manifest.csv'

$sources = @(
    @{ File = 'wdl345.txt'; Kind = 'WDL'; Group = '345' }
    @{ File = 'dtz345.txt'; Kind = 'DTZ'; Group = '345' }
    @{ File = 'wdl6.txt';   Kind = 'WDL'; Group = '6' }
    @{ File = 'dtz6.txt';   Kind = 'DTZ'; Group = '6' }
    @{ File = 'wdl7.txt';   Kind = 'WDL'; Group = '7' }
    @{ File = 'dtz7.txt';   Kind = 'DTZ'; Group = '7' }
)

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add('name;kind;pieces;expected_folder;expected_md5;source_file')
$total = 0

foreach ($src in $sources) {
    $path = Join-Path $checksumDir $src.File
    if (-not (Test-Path -LiteralPath $path)) {
        Write-Error "checksum file not found: $path"
        exit 1
    }
    $count = 0
    foreach ($raw in (Get-Content -LiteralPath $path)) {
        $line = "$raw".Trim()
        if ($line.Length -eq 0) { continue }
        $parts = $line.Split(':')
        if ($parts.Count -lt 2) {
            Write-Error "malformed line in $($src.File): $line"
            exit 1
        }
        $name = $parts[0].Trim()
        $md5 = (($parts[1..($parts.Count - 1)]) -join ':').Trim()
        $stem = [System.IO.Path]::GetFileNameWithoutExtension($name)
        $pieces = $stem.Length - 1
        switch ($src.Group) {
            '345' {
                if ($pieces -lt 3 -or $pieces -gt 5) {
                    Write-Error "bad piece count in $($src.File): $name has $pieces pieces (expected 3..5)"
                    exit 1
                }
                $folder = '3-4-5'
            }
            '6' {
                if ($pieces -ne 6) {
                    Write-Error "bad piece count in $($src.File): $name has $pieces pieces (expected 6)"
                    exit 1
                }
                if ($src.Kind -eq 'WDL') { $folder = '6-WDL' } else { $folder = '6-DTZ' }
            }
            '7' {
                if ($pieces -ne 7) {
                    Write-Error "bad piece count in $($src.File): $name has $pieces pieces (expected 7)"
                    exit 1
                }
                if ($src.Kind -eq 'WDL') { $folder = '7-WDL' } else { $folder = '7-DTZ' }
            }
        }
        $lines.Add(("{0};{1};{2};{3};{4};{5}" -f $name, $src.Kind, $pieces, $folder, $md5, $src.File))
        $count++
    }
    Write-Output ("{0}: {1} entries" -f $src.File, $count)
    $total += $count
}

$outDir = Split-Path $outPath -Parent
if (-not (Test-Path -LiteralPath $outDir)) {
    New-Item -ItemType Directory -Force -Path $outDir | Out-Null
}
[System.IO.File]::WriteAllLines($outPath, $lines, [System.Text.Encoding]::ASCII)

Write-Output ("MANIFEST total={0}" -f $total)
if ($total -ne 3022) { exit 1 }
exit 0
