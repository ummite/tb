$ErrorActionPreference = "Continue"
$cl = "C:\Program Files\Microsoft Visual Studio\18\Insiders\VC\Tools\MSVC\14.51.36231\bin\Hostx64\x64\cl.exe"
$src = "src\tbgenp.c"
$out = "tbgenp.i"

Write-Host "=== Preprocessing $src to $out ==="

if (Test-Path $out) { Remove-Item $out -Force -ErrorAction SilentlyContinue }

$defines = @(
  "/D", "NDEBUG",
  "/D", "_CRT_SECURE_NO_WARNINGS",
  "/D", "_CRT_NONSTDC_NO_DEPRECATE",
  "/D", "_CONSOLE",
  "/D", "HAS_PAWNS",
  "/D", "MAGIC",
  "/D", "USE_POPCNT",
  "/D", "BMI2",
  "/D", "TBPIECES=7",
  "/D", "COMPRESSION_THREADS=6",
  "/D", "REGULAR",
  "/D", "LZ4",
  "/D", "_WIN64",
  "/D", "_MSC_VER=1930"
)

$argsList = @(
  "/P",
  "/Fi$out",
  "/nologo",
  "/I", "src",
  "/std:c11",
  "/W3",
  "/EHs-c-",
  "/GR-"
) + $defines + @($src)

Write-Host "Running cl.exe with preprocess..."
& $cl @argsList 2>&1 | Tee-Object -Variable clOut | Out-Null

$exit = $LASTEXITCODE
Write-Host "cl.exe exit code: $exit"

if (Test-Path $out) {
  $size = (Get-Item $out).Length
  Write-Host "SUCCESS: $out created, size $size bytes"
  
  $content = Get-Content $out -Raw -ErrorAction SilentlyContinue
  $checks = @(
    "REDUCE_PLY 121",
    "STAT_PAWN_WIN",
    "void set_tbl_to_wdl",
    "void iterate",
    "void calc_pawn_moves_w(struct thread_data *thread)",
    "#include `"rtbgenp.c`"",
    "genericp.c"
  )
  foreach ($c in $checks) {
    if ($content -match [regex]::Escape($c)) {
      Write-Host "PRESENT: $c"
    } else {
      Write-Host "ABSENT : $c"
    }
  }
} else {
  Write-Host "FAIL: no $out produced"
  $clOut | Select-Object -Last 20
}
Write-Host "=== Preprocess script done ==="