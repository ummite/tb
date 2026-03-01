# Tablebase Generator - Future Improvements

This document tracks potential improvements and ideas for future development.

## Current Status

### Completed
- [x] GCC build system (Makefile-based)
- [x] VS2026 project files (.vcxproj) with BMI2, LZ4, C11, LTCG
- [x] Basic build scripts (build.sh, build.bat)
- [x] Verification scripts (verify_all.bat)
- [x] Status tracking (status.bat)
- [x] 78 tablebases generated with WDL and DTZ files
- [x] Executables exist in bin/ directory
- [x] tbcheck verification works for most files
- [x] CMake cross-platform build system
- [x] MSVC compatibility in defs.h (likely/unlikely/assume macros)
- [x] MSVC compatibility in wincompat.h (inttypes.h macros)
- [x] CMakeLists.txt with all chess variants
- [x] CMake support for BMI2, MAGIC, HYPER attack methods
- [x] CMake support for ZSTD compression option
- [x] README.md with Quick Start section
- [x] PROJECT_STATUS.md documentation
- [x] Clean project structure documentation

### Known Issues
- [ ] KQQRvK.rtbw file size not aligned to 64 bytes
- [ ] Some rtbver verification errors found in KQvK
- [ ] Several tablebases have unusually small sizes (may be correct for simple positions)

## Potential Improvements

### 1. Build System Enhancements

#### VS2026 Support (COMPLETED)
- [x] Create proper CMakeLists.txt for cross-platform builds
- [x] Add support for ZSTD compression library in builds
- [x] Add compiler-specific optimization flags (LTCG, /O2, /GL)
- [x] Support for MSVC /arch:AVX2 for BMI2
- [x] Multi-processor compilation (/MP)
- [x] Permissive mode (/permissive-) for C11 compliance

#### GCC/MinGW Support (COMPLETED)
- [x] Fix Makefile warnings (duplicate targets fixed)
- [x] Add support for parallel builds with `-j` flag
- [x] Add `--disk` option support for large tablebases
- [x] Support for different compression levels
- [x] CMake support for GCC/Clang with -march=native, -flto=auto

### 2. Code Quality Improvements

#### C11 Compliance (COMPLETED)
- [x] Added MSVC compatibility for likely/unlikely macros in defs.h
- [x] Added assume() macro for compiler optimizations
- [x] CMakeLists.txt with LanguageStandard_C=stdc11
- [ ] Review all source files for C99 vs C11 compatibility
- [ ] Add proper `restrict` qualifiers where appropriate
- [ ] Use `stdint.h` types consistently instead of custom types

#### Memory Safety
- [ ] Add bounds checking for array accesses
- [ ] Implement proper error handling for malloc failures
- [ ] Add memory leak detection in debug builds

#### Performance Optimization
- [ ] Profile and optimize hot paths in compression algorithms
- [ ] Add SIMD optimizations (AVX2, AVX-512)
- [ ] Consider using memory-mapped files for large tablebase access

#### Build System (COMPLETED)
- [x] Fixed duplicate target warnings in src/Makefile
- [x] Created build.sh for GCC builds with info/debug/release/clean targets
- [x] Created build.bat for VS2026 with MSBuild auto-detection
- [x] Enhanced all VS2026 .vcxproj files with:
  - BMI2 support (/arch:AVX2)
  - LZ4 compression (built-in)
  - C11 standard (LanguageStandard_C=stdc11)
  - LTCG (Link Time Code Generation)
  - Multi-processor compilation (/MP)
  - Permissive mode (/permissive)
  - /OPT:REF /OPT:ICF linker optimizations
  - InlineFunctionExpansion=OnlyExplicitInline

### 3. Chess Variant Support

Currently supports:
- Regular chess (default)
- Atomic chess (atbgen)
- Suicide chess (stbgen)
- Giveaway chess (gtbgen)
- Shatranj (jtbgen)

Potential additions:
- [ ] Chess960/Fischer Random support
- [ ] King of the Hill variant
- [ ] Three-check chess
- [ ] Crazyhouse (more complex, requires new algorithms)

### 4. Tablebase Generation

#### Efficiency
- [ ] Add progress indicators during generation
- [ ] Support for resuming interrupted generation
- [ ] Better RAM management for 6+ piece tables
- [ ] Add `--stats` option to track generation metrics

#### Quality
- [ ] Fix KQQRvK file alignment issue
- [ ] Investigate rtbver verification errors
- [ ] Add comprehensive integrity testing
- [ ] Generate all remaining 3-5 piece combinations

### 5. Verification and Testing

#### Automated Testing
- [ ] Create unit tests for core algorithms
- [ ] Add integration tests for full generation pipeline
- [ ] Create test suite for verification errors

#### Continuous Integration
- [ ] Add GitHub Actions for automated builds
- [ ] Add automated testing on each commit
- [ ] Generate benchmark results for performance tracking

### 6. Documentation

#### User Documentation
- [ ] Create comprehensive user guide
- [ ] Add examples for common use cases
- [ ] Document environment variable requirements
- [ ] Create troubleshooting FAQ

#### Developer Documentation
- [ ] Add architecture overview document
- [ ] Document compression algorithm in detail
- [ ] Add code comments for complex algorithms
- [ ] Create contribution guidelines

### 7. Runtime Enhancements

#### Compression
- [ ] Add ZSTD support as alternative to LZ4
- [ ] Support for different compression levels
- [ ] Add incremental compression for large files

#### Probing
- [ ] Add command-line probing tool
- [ ] Support for querying tablebases from chess engines
- [ ] Add UCI-compatible probing interface

## Ideas for Future Sessions

1. **Cross-platform CMake build**: Replace Makefile with CMake for better cross-platform support
2. **CI/CD pipeline**: Set up automated testing and building on GitHub Actions
3. **Performance profiling**: Use tools like valgrind or Intel VTune to identify bottlenecks
4. **6-piece tablebases**: Add support for generating 6-piece tables with `--disk` option
5. **7-piece tablebases**: Research and document requirements for 7-piece generation
6. **Python wrapper**: Create Python bindings for tablebase probing
7. **GUI front-end**: Build a simple GUI for tablebase generation and verification
8. **Tablebase browser**: Create a tool for visualizing tablebase contents

## Technical Debt

### Files to Clean Up
- Remove redundant backup files (Backup1, Backup2, etc.)
- Consolidate multiple build scripts into unified system
- Remove old build artifacts from build/ and obj* directories

### Deprecated Code
- [ ] Review and remove unused code paths
- [ ] Update deprecated compiler flags
- [ ] Remove hardcoded paths in favor of environment variables

### Incomplete Features
- [ ] `--disk` option not fully tested
- [ ] `--stats` option needs documentation
- [ ] Multi-threading needs testing on different platforms

## Latest Improvements (This Session)

### CMakeLists.txt Enhancements
- Fixed GIVEAWAY_FLAGS to include -DSUICIDE (giveaway is a subset of suicide)
- Added COMPRESSION_THREADS_COUNT option (default: 6)
- Added MAX_TBPIECES option (default: 7)
- Added stbver and stbverp to suicide target
- Added gtbver and gtbverp to giveaway target
- Improved build configuration for all variants

### Makefile Improvements
- Fixed suicide target to include stbver and stbverp
- Fixed giveaway target to include gtbver and gtbverp
- Added target rules for stbver, stbverp, gtbver, gtbverp
- Ensures complete build consistency with CMakeLists.txt

### VS2026 Project File Enhancements
All .vcxproj files (tbgen, tbgenp, tbver, tbverp, tbcheck) enhanced with:
- **Permissive mode**: `<Permissive>false</Permissive>` for stricter C11 compliance
- **BMI2 support**: `<AdditionalOptions>/arch:AVX2</AdditionalOptions>`
- **LTCG optimizations**: `/LTCG /OPT:REF /OPT:ICF` linker flags
- **Inline expansion**: `InlineFunctionExpansion=OnlyExplicitInline`
- **Multi-processor compilation**: `<MultiProcessorCompilation>true</MultiProcessorCompilation>`

### Cross-Platform Compatibility
- **defs.h**: MSVC compatibility for likely/unlikely/assume macros
- **wincompat.h**: MSVC inttypes.h macros (PRId64 "I64d", PRIu64 "I64u", PRIx64 "I64x")
- **CMakeLists.txt**: Configured for both MSVC and GCC/Clang with platform-specific optimizations

### Documentation Updates
- README.md enhanced with CMake Quick Start section
- PROJECT_STATUS.md created with comprehensive status report
- docs/IMPROVEMENTS.md updated with completed items and latest improvements

---

## Notes

This document should be reviewed and updated regularly as the project evolves. Ideas listed here can be picked up in future sessions based on priority and available resources.

---

*Last updated: 2026-03-01*