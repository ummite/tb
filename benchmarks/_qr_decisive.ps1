# Test decisif Q/R : regenere KRvKR + KQvKB avec le nouveau tbgen.exe (build 2026-09-14),
# compare SHA-256 vs T:\Syzygy\3-4-5 (officiel 2021).
# Usage : powershell -NoProfile -ExecutionPolicy Bypass -File benchmarks\_qr_decisive.ps1
$root = "C:\Programmation\tb-1"
$bin  = Join-Path $root "bin"
$out  = Join-Path $root "test_qr_new"
if (-not (Test-Path $out)) { New-Item -ItemType Directory -Path $out | Out-Null }
$env:RTBPATH = "C:\Programmation\tb-1\rtb_sub_34"
$env:RTBSTATSDIR = $out
$ref = "T:\Syzygy\3-4-5"
$fail = 0

function Run-Gen($exe, $argstr, $workdir) {
    $exePath = Join-Path $bin $exe
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $exePath
    $psi.Arguments = $argstr
    $psi.WorkingDirectory = $workdir
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.UseShellExecute = $false
    $p = [System.Diagnostics.Process]::Start($psi)
    $o = $p.StandardOutput.ReadToEnd()
    $e = $p.StandardError.ReadToEnd()
    $p.WaitForExit()
    return [pscustomobject]@{ Exit = $p.ExitCode; Out = $o; Err = $e }
}

foreach ($t in @("KRvKR", "KQvKB")) {
    $sw = [Diagnostics.Stopwatch]::StartNew()
    $r = Run-Gen "tbgen.exe" "-t 12 $t" $out
    $sw.Stop()
    $r.Out | Set-Content (Join-Path $out "$t.out") -Encoding ASCII
    $r.Err | Set-Content (Join-Path $out "$t.err") -Encoding ASCII
    Write-Host "$t exit=$($r.Exit) wall=$([math]::Round($sw.Elapsed.TotalSeconds,1))s"
    if ($r.Exit -ne 0) { Write-Host "FAIL GEN $t"; $fail++ }
}

Write-Host "=== SHA-256 vs $ref ==="
foreach ($t in @("KRvKR", "KQvKB")) {
    foreach ($ext in @("rtbw", "rtbz")) {
        $f = Join-Path $out "$t.$ext"
        $rf = Join-Path $ref "$t.$ext"
        if (-not (Test-Path $f)) { Write-Host "MISSING $f"; $fail++; continue }
        if (-not (Test-Path $rf)) { Write-Host "MISSING REF $rf"; $fail++; continue }
        $s1 = (Get-FileHash $f -Algorithm SHA256).Hash
        $s2 = (Get-FileHash $rf -Algorithm SHA256).Hash
        if ($s1 -eq $s2) {
            Write-Host "IDENTICAL $t.$ext  $s1"
        } else {
            Write-Host "DIFFER $t.$ext  new=$($s1.Substring(0,16)).. ref=$($s2.Substring(0,16)).."
            $fail++
        }
    }
}
if ($fail -eq 0) { Write-Host "QR_DECISIVE PASS (4/4 byte-identical vs officiel)" }
else { Write-Host "QR_DECISIVE FAIL ($fail anomalies)" }
