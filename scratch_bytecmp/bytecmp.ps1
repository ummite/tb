# bytecmp.ps1 - byte-level comparison: generated vs reference tablebase files
# Usage: powershell -NoProfile -ExecutionPolicy Bypass -File bytecmp.ps1
# Pure ASCII, CRLF. Read-only: data files are never modified.

$ErrorActionPreference = 'Stop'

# self-check: this script itself must be pure ASCII + CRLF
$selfBytes = [System.IO.File]::ReadAllBytes($MyInvocation.MyCommand.Path)
$selfNonAscii = 0
$selfLoneLf = 0
$selfCrlf = 0
for ($i = 0; $i -lt $selfBytes.Length; $i++) {
    $b = $selfBytes[$i]
    if ($b -gt 127) { $selfNonAscii++ }
    if ($b -eq 10) {
        if ($i -gt 0 -and $selfBytes[$i - 1] -eq 13) { $selfCrlf++ } else { $selfLoneLf++ }
    }
}
Write-Host ('script self-check: bytes={0} nonAscii={1} crlf={2} loneLf={3}' -f $selfBytes.Length, $selfNonAscii, $selfCrlf, $selfLoneLf)
Write-Host ''

function To-Hex {
    param([byte[]]$d, [int]$start, [int]$len)
    if ($start -lt 0) { $start = 0 }
    $end = $start + $len
    if ($end -gt $d.Length) { $end = $d.Length }
    if ($end -le $start) { return '(none)' }
    $sb = New-Object System.Text.StringBuilder
    for ($i = $start; $i -lt $end; $i++) {
        [void]$sb.Append($d[$i].ToString('X2'))
        if ($i -lt ($end - 1)) { [void]$sb.Append(' ') }
    }
    return $sb.ToString()
}

function Compare-Pair {
    param([string]$Id, [string]$GenPath, [string]$RefPath, [int]$HeadLen)

    Write-Host ('===== PAIR {0} =====' -f $Id)
    Write-Host ('GEN: {0}' -f $GenPath)
    Write-Host ('REF: {0}' -f $RefPath)

    if (-not (Test-Path -LiteralPath $GenPath)) { Write-Host 'RESULT: GEN FILE MISSING'; Write-Host ''; return }
    if (-not (Test-Path -LiteralPath $RefPath)) { Write-Host 'RESULT: REF FILE MISSING'; Write-Host ''; return }

    $g = [System.IO.File]::ReadAllBytes($GenPath)
    $r = [System.IO.File]::ReadAllBytes($RefPath)
    Write-Host ('sizes: gen={0} ref={1}' -f $g.Length, $r.Length)

    Write-Host ('GEN head {0} bytes:' -f $HeadLen)
    Write-Host (To-Hex $g 0 $HeadLen)
    Write-Host ('REF head {0} bytes:' -f $HeadLen)
    Write-Host (To-Hex $r 0 $HeadLen)

    # trailer: last 8 bytes = CityHash checksum
    $trSame = $null
    if ($g.Length -ge 8 -and $r.Length -ge 8) {
        $trSame = $true
        $gs = $g.Length - 8
        $rs = $r.Length - 8
        for ($i = 0; $i -lt 8; $i++) {
            if ($g[$gs + $i] -ne $r[$rs + $i]) { $trSame = $false; break }
        }
    }
    Write-Host ('trailer last8 gen: {0}' -f (To-Hex $g ([Math]::Max(0, $g.Length - 8)) 8))
    Write-Host ('trailer last8 ref: {0}' -f (To-Hex $r ([Math]::Max(0, $r.Length - 8)) 8))
    if ($trSame -eq $true) { Write-Host 'trailer checksum: SAME' }
    elseif ($trSame -eq $false) { Write-Host 'trailer checksum: DIFF' }
    else { Write-Host 'trailer checksum: n/a' }

    $n = $g.Length
    $sizeMismatch = ($g.Length -ne $r.Length)
    if ($sizeMismatch -and $r.Length -lt $n) { $n = $r.Length }

    # first differing byte (scan by uint32 words for speed)
    $diff = -1
    $nwords = [int][Math]::Floor($n / 4)
    if ($nwords -gt 0) {
        $ua = [System.Array]::CreateInstance([System.UInt32], $nwords)
        $ub = [System.Array]::CreateInstance([System.UInt32], $nwords)
        [System.Buffer]::Copy($g, 0, $ua, 0, $nwords * 4)
        [System.Buffer]::Copy($r, 0, $ub, 0, $nwords * 4)
        for ($i = 0; $i -lt $nwords; $i++) {
            if ($ua[$i] -ne $ub[$i]) { $diff = $i * 4; break }
        }
        if ($diff -lt 0) {
            $tail = $nwords * 4
            for ($i = $tail; $i -lt $n; $i++) {
                if ($g[$i] -ne $r[$i]) { $diff = $i; break }
            }
        }
    }
    else {
        for ($i = 0; $i -lt $n; $i++) {
            if ($g[$i] -ne $r[$i]) { $diff = $i; break }
        }
    }

    if ($diff -lt 0) {
        if (-not $sizeMismatch) {
            Write-Host 'RESULT: IDENTICAL'
        }
        else {
            Write-Host ('RESULT: common prefix identical, size mismatch (first extra byte at offset {0} / 0x{1:X})' -f $n, $n)
        }
    }
    else {
        Write-Host ('FIRST-DIFF @ offset {0} (0x{1:X})' -f $diff, $diff)
        $ws = $diff - 16
        if ($ws -lt 0) { $ws = 0 }
        Write-Host ('window 32 bytes @ 0x{0:X} (diff at +{1} in window):' -f $ws, ($diff - $ws))
        Write-Host ('GEN: {0}' -f (To-Hex $g $ws 32))
        Write-Host ('REF: {0}' -f (To-Hex $r $ws 32))
    }
    Write-Host ''
}

Compare-Pair 'A' 'C:\Programmation\tb-1\test_gen_4pc_full\KRvKR.rtbw' 'T:\Syzygy\3-4-5\KRvKR.rtbw' 256
Compare-Pair 'B' 'C:\Programmation\tb-1\test_gen_4pc_full\KRvKR.rtbz' 'T:\Syzygy\3-4-5\KRvKR.rtbz' 64
Compare-Pair 'C' 'C:\Programmation\tb-1\test_gen_4pc_full\KQvKB.rtbw' 'T:\Syzygy\3-4-5\KQvKB.rtbw' 64
Compare-Pair 'D' 'C:\Programmation\tb-1\test_gen_4pc_full\KQvKR.rtbz' 'T:\Syzygy\3-4-5\KQvKR.rtbz' 64
Compare-Pair 'E' 'C:\Programmation\tb-1\test_gen_5pc_full\KRRvKR.rtbw' 'T:\Syzygy\3-4-5\KRRvKR.rtbw' 64
Compare-Pair 'F' 'C:\Programmation\tb-1\test_gen_5pc_full\KRRvKR.rtbz' 'T:\Syzygy\3-4-5\KRRvKR.rtbz' 64
Compare-Pair 'G' 'C:\Programmation\tb-1\test_gen_4pc_full\KBvKP.rtbw' 'T:\Syzygy\3-4-5\KBvKP.rtbw' 64
