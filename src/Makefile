# =============================================================================
# tb-1 Tablebase Generator Build System
# =============================================================================
# Features:
# - Parallel build support (make -j N)
# - Debug and Release build modes
# - Platform auto-detection
# - Compression library selection
# - Variant builds (regular, atomic, suicide, giveaway, shatranj)
# =============================================================================

# === BUILD CONFIGURATION ===

# Build optimization level: 0, 1, 2, 3, s, z
BUILD_LEVEL ?= 3

# Debug mode: set to 1 for debug build
DEBUG ?= 0

# === PLATFORM DETECTION ===

# Auto-detect compiler and platform
UNAME_S := $(shell sh -c 'uname -s 2>/dev/null || echo Windows')
UNAME_M := $(shell sh -c 'uname -m 2>/dev/null || echo x86_64')

# Compiler detection (use gcc/g++ for MinGW/MinGW-w64)
CC ?= gcc
CXX ?= g++

# Platform-specific flags
ifeq ($(UNAME_S),Linux)
    PLATFORM_FLAGS += -D_GNU_SOURCE
    PLATFORM_LIBS += -pthread
    COMPILER_NAME = GCC
else ifeq ($(UNAME_S),Darwin)
    PLATFORM_FLAGS += -D_DARWIN_C_SOURCE
    PLATFORM_LIBS += -pthread
    COMPILER_NAME = Clang/GCC
else
    # Windows/MinGW
    PLATFORM_FLAGS += -DWIN32 -D_USE_MATH_DEFINES
    PLATFORM_LIBS += -lpthread
    COMPILER_NAME = MinGW
endif

# === COMPILER FLAGS ===

# Base optimization flags based on BUILD_LEVEL
ifeq ($(BUILD_LEVEL),0)
    OPT_FLAGS = -O0 -g3
else ifeq ($(BUILD_LEVEL),1)
    OPT_FLAGS = -O1
else ifeq ($(BUILD_LEVEL),2)
    OPT_FLAGS = -O2
else ifeq ($(BUILD_LEVEL),3)
    OPT_FLAGS = -O3
else ifeq ($(BUILD_LEVEL),s)
    OPT_FLAGS = -Os
else ifeq ($(BUILD_LEVEL),z)
    OPT_FLAGS = -Oz
else
    OPT_FLAGS = -O3
endif

# Debug mode overrides
ifeq ($(DEBUG),1)
    OPT_FLAGS = -O0 -g3 -DDEBUG
endif

# Common compiler flags
CFLAGS_BASE = $(OPT_FLAGS) -march=native -pipe -Wall -Wextra -std=c11
CFLAGS_BASE += -ffast-math -funroll-loops -fomit-frame-pointer -flto=auto

# Platform flags
CFLAGS = $(CFLAGS_BASE) $(PLATFORM_FLAGS)

# Linker flags
LDFLAGS = -flto=auto $(PLATFORM_LIBS)

# === FEATURE FLAGS ===

# Attack generation method: -DMAGIC, -DHYPER, or -DBMI2
ATTACK_METHOD ?= MAGIC
FLAGS += -D$(ATTACK_METHOD)

# CPU feature flags
FLAGS += -DUSE_POPCNT

# Maximum pieces (3-7)
TBPIECES ?= 7
FLAGS += -DTBPIECES=$(TBPIECES)

# Compression: LZ4 (default) or ZSTD
USE_COMPRESSION ?= LZ4
ifeq ($(USE_COMPRESSION),ZSTD)
    FLAGS += -DUSE_ZSTD -DZSTD_LEVEL=6
    LDFLAGS += -lzstd
    COMPILER_NAME += (ZSTD)
else
    FLAGS += -DLZ4
    COMPILER_NAME += (LZ4)
endif

# Compression threads
COMPRESSION_THREADS ?= 6
FLAGS += -DCOMPRESSION_THREADS=$(COMPRESSION_THREADS)

# Export variables to sub-makefiles
export CC CFLAGS LDFLAGS FLAGS

# === TARGETS ===

.PHONY: all clean release debug variants

# Default: regular tablebase tools
all: rtbgen rtbgenp rtbver rtbverp tbcheck

# Debug build
debug:
	@$(MAKE) DEBUG=1 all

# Release build (optimized)
release:
	@$(MAKE) BUILD_LEVEL=3 all

# Show configuration info
info:
	@echo "============================================"
	@echo "tb-1 Build Configuration"
	@echo "============================================"
	@echo "Platform: $(UNAME_S) $(UNAME_M)"
	@echo "Compiler: $(CC) ($(COMPILER_NAME))"
	@echo "Build Level: $(BUILD_LEVEL)"
	@echo "Debug Mode: $(DEBUG)"
	@echo "Attack Method: $(ATTACK_METHOD)"
	@echo "Compression: $(USE_COMPRESSION)"
	@echo "Max Pieces: $(TBPIECES)"
	@echo "============================================"

# === VARIANT TARGETS ===

# Regular (standard chess)
regular: rtbgen rtbgenp rtbver rtbverp tbcheck
	@echo "Regular tablebase tools built."

# Atomic chess
atomic: atbgen atbgenp atbver atbverp tbcheck
	@echo "Atomic chess tablebase tools built."

# Suicide chess
suicide: stbgen stbgenp tbcheck
	@echo "Suicide chess tablebase tools built."

# Giveaway chess
giveaway: gtbgen gtbgenp tbcheck
	@echo "Giveaway chess tablebase tools built."

# Shatranj (ancient chess)
shatranj: jtbgen jtbgenp jtbver jtbverp tbcheck
	@echo "Shatranj tablebase tools built."

# Build all variants
variants: regular atomic suicide giveaway shatranj
	@echo "All variant tools built."

# === CLEAN TARGETS ===

# Clean all variants
clean:
	@$(MAKE) -f Makefile.regular clean
	@$(MAKE) -f Makefile.atomic clean
	@$(MAKE) -f Makefile.suicide clean
	@$(MAKE) -f Makefile.giveaway clean
	@$(MAKE) -f Makefile.shatranj clean
	@echo "Clean complete."

# Clean specific variant
aclean:
	@$(MAKE) -f Makefile.atomic clean

sclean:
	@$(MAKE) -f Makefile.suicide clean

gclean:
	@$(MAKE) -f Makefile.giveaway clean

jclean:
	@$(MAKE) -f Makefile.shatranj clean

# === ALIASES ===

# tbgen aliases (for convenience)
tbgen: rtbgen
tbgenp: rtbgenp
tbver: rtbver
tbverp: rtbverp

# === VARIANT BUILD TARGETS ===

# Regular (standard chess)
rtbgen:
	@$(MAKE) -f Makefile.regular rtbgen

rtbgenp:
	@$(MAKE) -f Makefile.regular rtbgenp

rtbver:
	@$(MAKE) -f Makefile.regular rtbver

rtbverp:
	@$(MAKE) -f Makefile.regular rtbverp

tbcheck:
	@$(MAKE) -f Makefile.regular tbcheck

# Atomic chess
atbgen:
	@$(MAKE) -f Makefile.atomic atbgen

atbgenp:
	@$(MAKE) -f Makefile.atomic atbgenp

atbver:
	@$(MAKE) -f Makefile.atomic atbver

atbverp:
	@$(MAKE) -f Makefile.atomic atbverp

# Suicide chess
stbgen:
	@$(MAKE) -f Makefile.suicide stbgen

stbgenp:
	@$(MAKE) -f Makefile.suicide stbgenp

# Giveaway chess
gtbgen:
	@$(MAKE) -f Makefile.giveaway gtbgen

gtbgenp:
	@$(MAKE) -f Makefile.giveaway gtbgenp

# Shatranj
jtbgen:
	@$(MAKE) -f Makefile.shatranj jtbgen

jtbgenp:
	@$(MAKE) -f Makefile.shatranj jtbgenp

jtbver:
	@$(MAKE) -f Makefile.shatranj jtbver

jtbverp:
	@$(MAKE) -f Makefile.shatranj jtbverp

.PHONY: all clean debug release variants regular atomic suicide giveaway shatranj \
        rtbgen rtbgenp rtbver rtbverp tbcheck aclean sclean gclean jclean \
        tbgen tbgenp tbver tbverp info