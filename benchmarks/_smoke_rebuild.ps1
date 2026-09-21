# Smoke test post-rebuild : nb threads, determinisme, tbcheck, fix AV tbgenp.
# Usage : powershell -NoProfile -ExecutionPolicy Bypass -File benchmarks\_smoke_rebuild.ps1
$root   = "C:\Programmation\tb-1"
$bin    = Join-Path $root "bin"
$smokeA = Join-Path $root "test_smoke_A"
$smokeB = Join-Path $root "test_smoke_B"
foreach ($d in @($smokeA, $smokeB)) {
    if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d | Out-Null }
}
$env:RTBPATH = "C:\Programmation\tb-1\rtb_sub_34"
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
    $out = $p.StandardOutput.ReadToEnd()
    $err = $p.StandardError.ReadToEnd()
    $p.WaitForExit()
    return [pscustomobject]@{ Exit = $p.ExitCode; Out = $out; Err = $err }
}

# 1) KRvK dans dir A (threads par defaut = nb coeurs, attendu 24)
$r = Run-Gen "tbgen.exe" "KRvK" $smokeA
$r.Out | Set-Content (Join-Path $smokeA "KRvK_A.out") -Encoding ASCII
$thr = ($r.Out -split "`n" | Select-String "threads") -join " | "
Write-Host "KRvK_A exit=$($r.Exit) :: $thr"
if ($r.Exit -ne 0) { Write-Host "FAIL KRvK_A"; $fail++ }

# 2) KRvK dans dir B (determinisme)
$r2 = Run-Gen "tbgen.exe" "KRvK" $smokeB
if ($r2.Exit -ne 0) { Write-Host "FAIL KRvK_B"; $fail++ }
foreach ($ext in @("rtbw", "rtbz")) {
    $ha = (Get-FileHash (Join-Path $smokeA "KRvK.$ext") -Algorithm SHA256).Hash
    $hb = (Get-FileHash (Join-Path $smokeB "KRvK.$ext") -Algorithm SHA256).Hash
    if ($ha -eq $hb) { Write-Host "DETERMINISM OK KRvK.$ext $ha" } else { Write-Host "FAIL DETERMINISM KRvK.$ext"; $fail++ }
}

# 3) tbcheck sur dir A
foreach ($ext in @("rtbw", "rtbz")) {
    $tc = Run-Gen "tbcheck.exe" (Join-Path $smokeA "KRvK.$ext") $smokeA
    if ($tc.Exit -ne 0) { Write-Host "FAIL tbcheck KRvK.$ext"; $fail++ } else { Write-Host "TBCHECK OK KRvK.$ext" }
}

# 4) Fix AV tbgenp : tables 4pc pawnful qui crashaient avant
foreach ($t in @("KPPvK", "KQvKP", "KPvKP", "KNPvKR")) {
    $r3 = Run-Gen "tbgenp.exe" $t $smokeA
    $r3.Out | Set-Content (Join-Path $smokeA "$t.out") -Encoding ASCII
    $r3.Err | Set-Content (Join-Path $smokeA "$t.err") -Encoding ASCII
    $w = Join-Path $smokeA "$t.rtbw"
    $ok = ($r3.Exit -eq 0) -and (Test-Path $w) -and ((Get-Item $w).Length -gt 0)
    if ($ok) { Write-Host "AVFIX OK $t size=$((Get-Item $w).Length)" } else { Write-Host "FAIL AVFIX $t exit=$($r3.Exit)"; $fail++ }
    if ($ok) {
        $tc = Run-Gen "tbcheck.exe" $w $smokeA
        if ($tc.Exit -ne 0) { Write-Host "FAIL tbcheck $t.rtbw"; $fail++ } else { Write-Host "TBCHECK OK $t.rtbw" }
    }
}

Write-Host "SMOKE_RESULT fail=$fail"
