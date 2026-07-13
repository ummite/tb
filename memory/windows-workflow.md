# Windows workflow notes + power-loss resume

## After power failure (Syzygy hash repair active 2026-07-10)

1. Read **`C:\Programmation\tb-1\RESUME_AFTER_OUTAGE.md`** (full checklist).
2. Confirm drives: `T:`, ideally `A:`/`S:` for local repairs.
3. Run:
   ```powershell
   cd C:\Programmation\tb-1
   .\Repair-Syzygy-BadHashes.ps1
   ```
4. When finished:
   ```powershell
   .\Verify-Syzygy-OfficialHashes.ps1 -Root T:\Syzygy
   ```
5. Update `RESUME_AFTER_OUTAGE.md` and `T:\Syzygy\STATE.md` to COMPLETE.

## Build (VS Insiders)
```powershell
& "C:\Program Files\Microsoft Visual Studio\18\Insiders\MSBuild\Current\Bin\MSBuild.exe" src\tbgen.vcxproj /p:Configuration=Release /p:Platform=x64
# Output often src\bin\tbgen.exe — copy to bin\rtbgen.exe as needed
```

## Master Syzygy path structure
```
T:\Syzygy\3-6men\
T:\Syzygy\7men\4v3_pawnful|4v3_pawnless|5v2_*|6v1_*\
T:\Syzygy\8men\   (scaffold only)
```
