# Tasks for Unified Tablebase Generator System
Last updated: 2026-02-27

## Quick Reference
**Essential Commands:**

| Task | Command |
|------|---------|
| **Build (GCC)** | `./build.sh` or `make -C src all` |
| **Build (VS2026)** | `.\\build.bat` or `msbuild tbgen.sln` |
| **Generate All** | `.\generate_all.bat` (requires RTBPATH) |
| **Verify All** | `.\verify_all.bat` |
| **Check Status** | `.\status.bat` |
| **Show Todo** | `.\todo.bat` |

---

## Status Summary
- **Completed**: VS2026 build system, pre-generated tablebases (76 files)
- **In Progress**: Unified generation system
- **Pending**: Complete 3-5 piece generation, verification system

---

## Phase 1: Build System (COMPLETED)

### Task 1.1: GCC Build Script
**Status:** Ready to implement
**Command:** `make -C src all`
**Output:** `bin/rtbgen.exe`, `bin/rtbgenp.exe`, etc.

**Implementation:**
```bash
#!/bin/bash
# build.sh - GCC build script

set -e
cd src
make all
echo "Build complete. Binaries in bin/"
```

### Task 1.2: VS2026 Build Script
**Status:** COMPLETED
**Command:** `msbuild tbgen.sln /p:Configuration=Release /p:Platform=x64`
**Output:** `bin/rtbgen.exe`, `bin/rtbgenp.exe`, etc.

**Implementation:**
```cmd
@echo off
rem build.bat - VS2026 build script

set MSBUILD="C:\Program Files\Microsoft Visual Studio\18\Insiders\MSBuild\Current\Bin\MSBuild.exe"
%MSBUILD% "C:\Programmation\tb-1\tbgen.sln" /p:Configuration=Release /p:Platform=x64 /verbosity:minimal

if %ERRORLEVEL% EQU 0 (
    echo Build complete. Binaries in bin/
) else (
    echo Build failed with error %ERRORLEVEL%
    exit /b %ERRORLEVEL%
)
```

### Task 1.3: Verify Executables
**Status:** COMPLETED
**Check:** All 5 executables exist in `bin/` directory

- [x] `bin/rtbgen.exe` - Pawnless generator
- [x] `bin/rtbgenp.exe` - Pawnful generator
- [x] `bin/rtbver.exe` - Pawnless verifier
- [x] `bin/rtbverp.exe` - Pawnful verifier
- [x] `bin/tbcheck.exe` - Checksum checker

---

## Phase 2: Generation System (IN PROGRESS)

### Task 2.1: Create expected_combos.txt
**Status:** Pending
**Purpose:** Reference list of all legitimate 3-5 piece combinations

**Content Format:**
```
KQvK
KRvK
KNvK
KBvK
KQvKR
KQvRN
...
```

**Implementation:**
```bash
# Generate all legitimate combinations
# Pawnless 3-piece
KQvK, KRvK, KNvK, KBvK
# Pawnless 4-piece
KQQvK, KQNvK, KQBvK, KQRvK, KRRvK, KRNvK, KRBvK, KNNvK, KBNvK, KBBvK
# Pawnless 5-piece
KQQQvK, KQQNvK, KQQBvK, KQQRvK, KQRRvK, KQNNvK, KQNBvK, KQBBvK, KRRNvK, KRRBvK, KRNvK, KNNvK, KBNvK, KBBvK
# Pawnful 3-piece
KPvK, KRPvK, KNPvK, KBPvK, KQPvK
# Pawnful 4-piece
KAPPvK, KARPvK, KANPvK, KABPvK, KQPPvK, KQRPvK, KQNPvK, KQBPvK, KRNPvK, K RBPvK, KQBBvK, KQRPvK
# Pawnful 5-piece
KQRRPvK, KQRRBPvK, KQRRNPvK...
```

### Task 2.2: Create generate_all.bat
**Status:** Pending (replace existing script)
**Purpose:** Generate all combinations systematically

**Implementation:**
```cmd
@echo off
rem generate_all.bat - Generate all 3-5 piece combinations

cd /d C:\Programmation\tb-1\bin

if "%RTBPATH%"=="" (
    echo ERROR: RTBPATH not set
    echo Please run: set RTBPATH=C:\Programmation\tb-1\src
    exit /b 1
)

echo ==========================================
echo Tablebase Generator - All Combinations
echo ==========================================
echo.

call :generate 3 pawnless
call :generate 4 pawnless
call :generate 5 pawnless
call :generate 3 pawnful
call :generate 4 pawnful
call :generate 5 pawnful

echo.
echo ==========================================
echo Generation Complete!
echo ==========================================
goto :eof

:generate
set N=%1
set TYPE=%2
echo Generating %N% pieces (%TYPE%)...
echo.

if "%TYPE%"=="pawnless" (
    if %N% EQU 3 (
        call :gen_3p KQvK
        call :gen_3p KRvK
        call :gen_3p KNvK
        call :gen_3p KBvK
    )
    if %N% EQU 4 (
        call :gen_4p KQQvK
        call :gen_4p KQNvK
        call :gen_4p KQBvK
        call :gen_4p KQRvK
        call :gen_4p KRRvK
        call :gen_4p KRNvK
        call :gen_4p KRBvK
        call :gen_4p KNNvK
        call :gen_4p KBNvK
        call :gen_4p KBBvK
    )
    if %N% EQU 5 (
        call :gen_5p KQQQvK
        call :gen_5p KQQNvK
        call :gen_5p KQQBvK
        call :gen_5p KQQRvK
        call :gen_5p KQRRvK
        call :gen_5p KQNNvK
        call :gen_5p KQNBvK
        call :gen_5p KQBBvK
        call :gen_5p KRRNvK
        call :gen_5p KRRBvK
        call :gen_5p KRNvK
        call :gen_5p KNNvK
        call :gen_5p KBNvK
        call :gen_5p KBBvK
    )
) else (
    if %N% EQU 3 (
        call :gen_3p KPvK
        call :gen_3p KRPvK
        call :gen_3p KNPvK
        call :gen_3p KBPvK
        call :gen_3p KQPvK
    )
    if %N% EQU 4 (
        call :gen_4p KQPPvK
        call :gen_4p KQRPvK
        call :gen_4p KQNPvK
        call :gen_4p KQBPvK
        call :gen_4p KAPPvK
        call :gen_4p KARPvK
        call :gen_4p KANPvK
        call :gen_4p KABPvK
        call :gen_4p KRNPvK
        call :gen_4p K RBPvK
        call :gen_4p KQBBvK
        call :gen_4p KQRPvK
    )
)
goto :eof

:gen_3p
if not exist "%~1.rtbw" (
    echo   %1...
    rtbgen %1 >>generation_log.txt 2>&1
) else (
    echo   SKIP: %1 already exists
)
goto :eof

:gen_4p
if not exist "%~1.rtbw" (
    echo   %1...
    rtbgen %1 >>generation_log.txt 2>&1
) else (
    echo   SKIP: %1 already exists
)
goto :eof

:gen_5p
if not exist "%~1.rtbw" (
    echo   %1...
    rtbgen %1 >>generation_log.txt 2>&1
) else (
    echo   SKIP: %1 already exists
)
goto :eof
```

### Task 2.3: Create generate_all.sh (GCC version)
**Status:** Pending
**Purpose:** Same as generate_all.bat but for GCC/MinGW

---

## Phase 3: Verification System (PENDING)

### Task 3.1: Create verify_all.bat
**Status:** Pending
**Purpose:** Verify all generated tablebases

**Implementation:**
```cmd
@echo off
rem verify_all.bat - Verify all tablebases

cd /d C:\Programmation\tb-1\src

set PASS=0
set FAIL=0

echo ==========================================
echo Tablebase Verification
echo ==========================================
echo.

for %%f in (*.rtbw) do (
    echo Verifying %%f...
    tbver "%%f" >>verify_log.txt 2>&1
    if !ERRORLEVEL! EQU 0 (
        set /a PASS+=1
        echo   PASS: %%f
    ) else (
        set /a FAIL+=1
        echo   FAIL: %%f
    )
)

echo.
echo ==========================================
echo Summary: !PASS! passed, !FAIL! failed
echo ==========================================
```

### Task 3.2: Create verify_all.sh (GCC version)
**Status:** Pending
**Purpose:** Same as verify_all.bat but for GCC/MinGW

---

## Phase 4: Status System (PENDING)

### Task 4.1: Create status.bat
**Status:** Pending
**Purpose:** Show generation progress

**Implementation:**
```cmd
@echo off
rem status.bat - Show generation status

cd /d C:\Programmation\tb-1\src

set TOTAL=0
set GENERATED=0
set MISSING=0

echo ==========================================
echo Tablebase Generation Status
echo ==========================================
echo.

echo Checking 3-piece pawnless...
for %%f in (KQvK.rtbw KRvK.rtbw KNvK.rtbw KBvK.rtbw) do (
    set /a TOTAL+=1
    if exist "%%f" (
        set /a GENERATED+=1
    ) else (
        set /a MISSING+=1
        echo   MISSING: %%f
    )
)

echo Checking 4-piece pawnless...
for %%f in (KQQvK.rtbw KQNvK.rtbw KQBvK.rtbw KQRvK.rtbw KRRvK.rtbw KRNvK.rtbw KRBvK.rtbw KNNvK.rtbw KBNvK.rtbw KBBvK.rtbw) do (
    set /a TOTAL+=1
    if exist "%%f" (
        set /a GENERATED+=1
    ) else (
        set /a MISSING+=1
        echo   MISSING: %%f
    )
)

echo.
echo ==========================================
echo Status: %GENERATED%/%TOTAL% generated (%MISSING% missing)
echo ==========================================
```

### Task 4.2: Create todo.bat
**Status:** Pending
**Purpose:** Show only missing combinations

**Implementation:**
```cmd
@echo off
rem todo.bat - Show missing combinations

cd /d C:\Programmation\tb-1\src

echo ==========================================
echo Todo List - Missing Tablebases
echo ==========================================
echo.

for %%f in (KQvK.rtbw KRvK.rtbw KNvK.rtbw KBvK.rtbw) do (
    if not exist "%%f" echo KQvK
    if not exist "%%f" echo KRvK
    if not exist "%%f" echo KNvK
    if not exist "%%f" echo KBvK
)

echo.
echo To generate: set RTBPATH=... && cd bin && rtbgen <combo>
echo ==========================================
```

---

## Phase 5: Cleanup (PENDING)

### Task 5.1: Remove Redundant Scripts
**Status:** Pending
**Scripts to remove:**
- `build.bat` (replaced by unified build.bat)
- `build_vs.bat` (replaced by unified build.bat)
- `build_vs2026.bat` (replaced by unified build.bat)
- `src/generate_all_3.bat` (replaced by unified generate_all.bat)
- `src/generate_all_4.bat` (replaced by unified generate_all.bat)
- `src/generate_all.bat` (replaced by unified generate_all.bat)
- `src/generate_pawnful.bat` (replaced by unified generate_all.bat)

### Task 5.2: Update .gitignore
**Status:** COMPLETED
**Entries:**
```
*.o
*.P
*.swp
*.txt
*.rtbw
*.rtbz
rtbgen
rtbgenp
rtbver
rtbverp
tbcheck
build/
bin/
obj*/
*.obj
```

---

## Verification Checklist

After implementation, verify:

### Build Verification
- [ ] `./build.sh` compiles successfully (GCC)
- [ ] `.\\build.bat` compiles successfully (VS2026)
- [ ] All 5 executables in `bin/` directory
- [ ] Executables respond to arguments

### Generation Verification
- [ ] `.\generate_all.bat` runs without errors
- [ ] All expected combinations generated
- [ ] Log file shows progress
- [ ] Idempotent (second run shows only SKIP)

### Verification Verification
- [ ] `.\verify_all.bat` runs without errors
- [ ] All files pass verification
- [ ] Log file shows results

### Status Verification
- [ ] `.\status.bat` shows accurate counts
- [ ] `.\todo.bat` shows only missing combos

---

## Success Criteria

1. ✅ Both GCC and VS2026 builds work identically
2. ✅ `generate_all.bat` generates all 3-5 piece combos
3. ✅ System is idempotent (safe to run repeatedly)
4. ✅ `status.bat` accurately tracks progress
5. ✅ `verify_all.bat` correctly verifies files
6. ✅ All redundant scripts removed

---

## Notes

- **RTBPATH is required** for generation (subtablebases for retrograde analysis)
- **Pre-generated files exist**: 76 files in `src/` directory
- **Memory requirements**: 3-piece ~1GB, 4-piece ~8GB, 5-piece ~50GB
- **Time requirements**: 3-piece ~minutes, 4-piece ~hours, 5-piece ~days

---

## Related Files

- `GOAL.md` - High-level objectives and system overview
- `CLAUDE.md` - Project architecture and build instructions
- `plans/logical-foraging-pascal.md` - Detailed implementation plan