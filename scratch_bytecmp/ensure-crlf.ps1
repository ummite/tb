# ensure-crlf.ps1 - verify a script file is pure ASCII + CRLF (no BOM); normalize if needed.
# Usage: powershell -NoProfile -ExecutionPolicy Bypass -File ensure-crlf.ps1 <path>
param([Parameter(Position=0)][string]$Path)
$ErrorActionPreference = 'Stop'
$bytes = [System.IO.File]::ReadAllBytes($Path)
$off = 0
$bom = $false
if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
    $bom = $true
    $off = 3
}
$nonAscii = 0
$crlf = 0
$loneLf = 0
for ($i = $off; $i -lt $bytes.Length; $i++) {
    $b = $bytes[$i]
    if ($b -gt 127) { $nonAscii++ }
    if ($b -eq 10) {
        if ($i -gt $off -and $bytes[$i - 1] -eq 13) { $crlf++ } else { $loneLf++ }
    }
}
Write-Host ('file: {0}' -f $Path)
Write-Host ('bytes={0} bom={1} nonAscii={2} crlf={3} loneLf={4}' -f $bytes.Length, $bom, $nonAscii, $crlf, $loneLf)
if ($nonAscii -gt 0) {
    Write-Host 'ERROR: non-ASCII bytes present; file NOT rewritten'
    return
}
if ($bom -or $loneLf -gt 0) {
    $text = [System.Text.Encoding]::ASCII.GetString($bytes, $off, $bytes.Length - $off)
    $cr = [string][char]13
    $lf = [string][char]10
    $text = $text.Replace($cr + $lf, $lf)
    $text = $text.Replace($lf, $cr + $lf)
    [System.IO.File]::WriteAllText($Path, $text, (New-Object System.Text.ASCIIEncoding($false)))
    Write-Host 'rewritten: BOM stripped, all newlines normalized to CRLF, ASCII no BOM'
}
else {
    Write-Host 'OK: pure ASCII, CRLF, no BOM'
}
