# Project Cleanup Needed

This document lists files and directories that should be cleaned up to organize the project better.

## Backup Directories (Should Be Removed)

The following backup directories are no longer needed and should be removed:

- `Backup/`
- `Backup1/` through `Backup14/`

These appear to be old version backups that are taking up significant space.

## Build Artifacts (Can Be Removed)

The following build artifact directories can be removed (will be regenerated on next build):

- `build/` - Old CMake build directory
- `Release/` - Old release build directory
- `objsp/` - Object files for shatranj
- `objsr/` - Object files for regular

## Redundant Files

The following files are redundant and could be consolidated:

- `loop-prompt.md` - Duplicate of `loop_prompt.md`
- `cycle.log` - Empty log file
- `nul` - Empty file (likely a typo or leftover)
- `FromPowerShell.ps1` - Empty PowerShell script

## Build Scripts (Should Be Consolidated)

Multiple build scripts exist with overlapping functionality:

- `build.bat` - VS2026 build script
- `build_all.bat` - Build all variants
- `build_script.bat` - Generic build script
- `build_vs.bat` - VS build script
- `compile.bat` - Simple compile script

**Recommendation:** Keep `build.bat` and `build_all.bat`, remove the others or consolidate their functionality.

## Recommended Actions

1. **Backup directories**: Move to a separate backup location or remove
2. **Build artifacts**: Remove `build/`, `Release/`, `objsp/`, `objsr/`
3. **Empty files**: Remove `cycle.log`, `nul`, `FromPowerShell.ps1`
4. **Duplicate files**: Remove `loop-prompt.md`
5. **Build scripts**: Consolidate into `build.bat` and `build_all.bat`

---

*Last analyzed: 2026-03-01*