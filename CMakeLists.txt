cmake_minimum_required(VERSION 3.15)

project(tbgen VERSION 1.0.0 LANGUAGES C)

# C11 standard
set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_C_EXTENSIONS OFF)

# Platform detection
if(MSVC)
    message(STATUS "Building with MSVC")
    # MSVC optimization flags
    set(CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELEASE} /O2 /GL")
    set(CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG} /Od /Zi")
    if(CMAKE_BUILD_TYPE STREQUAL "Release")
        set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} /LTCG /OPT:REF /OPT:ICF")
    endif()
else()
    message(STATUS "Building with GCC/Clang")
    # GCC/Clang optimization flags
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -O2 -march=native -pipe")
    set(CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELEASE} -O3 -march=native -pipe -flto=auto")
    set(CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG} -O0 -g3")
endif()

# Common warning flags
if(MSVC)
    add_compile_options(/W3 /permissive-)
    # Enable multi-processor compilation
    add_compile_options(/MP)
else()
    add_compile_options(-Wall -Wextra -Wpedantic)
endif()

# Default to BMI2 for attack generation (modern CPUs)
option(ATTACK_METHOD "Attack generation method: BMI2, MAGIC, or HYPER" "BMI2")
if(ATTACK_METHOD STREQUAL "BMI2")
    add_compile_definitions(BMI2)
    if(MSVC)
        add_compile_options(/arch:AVX2)
    else()
        set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -mbmi2")
    endif()
elseif(ATTACK_METHOD STREQUAL "HYPER")
    add_compile_definitions(HYPER)
else()
    add_compile_definitions(MAGIC)
endif()

# Enable popcnt support if available (required for tablebase generation)
add_compile_definitions(USE_POPCNT)

# Compression method: ZSTD or LZ4 (default)
option(USE_ZSTD "Use ZSTD compression instead of LZ4" OFF)
if(USE_ZSTD)
    add_compile_definitions(USE_ZSTD)
    set(ZSTD_LEVEL 6)
    add_compile_definitions(ZSTD_LEVEL=${ZSTD_LEVEL})
    find_package(ZSTD REQUIRED)
    include_directories(${ZSTD_INCLUDE_DIRS})
    if(MSVC)
        target_link_libraries(tbgen PRIVATE ${ZSTD_LIBRARIES})
    else()
        target_link_libraries(tbgen PRIVATE zstd)
    endif()
else()
    add_compile_definitions(LZ4)
endif()

# Compression threads (default: 6)
set(COMPRESSION_THREADS_COUNT "6" CACHE STRING "Number of compression threads (default: 6)")
if(NOT COMPRESSION_THREADS_COUNT MATCHES "^[0-9]+$")
    message(WARNING "COMPRESSION_THREADS_COUNT must be a number, defaulting to 6")
    set(COMPRESSION_THREADS_COUNT "6")
endif()
add_compile_definitions(COMPRESSION_THREADS=${COMPRESSION_THREADS_COUNT})

# Maximum pieces (default: 8 for traditional/regular chess; variants may remain at 7)
option(MAX_TBPIECES "Maximum number of pieces (default: 8)" 8)
add_compile_definitions(TBPIECES=${MAX_TBPIECES})

# Directory structure
set(BIN_DIR ${CMAKE_BINARY_DIR}/bin)
set(SRC_DIR ${CMAKE_SOURCE_DIR}/src)
file(MAKE_DIRECTORY ${BIN_DIR})

# Common source files
set(COMMON_SOURCES
    ${SRC_DIR}/compress.c
    ${SRC_DIR}/huffman.c
    ${SRC_DIR}/threads.c
    ${SRC_DIR}/lz4.c
    ${SRC_DIR}/decompress.c
    ${SRC_DIR}/checksum.c
    ${SRC_DIR}/city-c.c
    ${SRC_DIR}/util.c
    ${SRC_DIR}/permute.c
    ${SRC_DIR}/virtual_table.c
    ${SRC_DIR}/vt_drive_utils.c
)

# Variant-specific flags
set(REGULAR_FLAGS -DREGULAR)
set(ATOMIC_FLAGS -DATOMIC)
set(SUICIDE_FLAGS -DSUICIDE)
set(GIVEAWAY_FLAGS -DGIVEAWAY -DSUICIDE)
set(LOSER_FLAGS -DGIVEAWAY -DSUICIDE -DLOSER)
set(SHATRANJ_FLAGS -DSHATRANJ)

# ============================================
# REGULAR (Standard Chess) - .rtbw/.rtbz
# ============================================

# rtbgen (pawnless generator)
set(RTBGEN_SRCS
    ${SRC_DIR}/tbgen.c
    ${SRC_DIR}/wincompat.c
    ${COMMON_SOURCES}
)
add_executable(rtbgen ${RTBGEN_SRCS})
target_compile_definitions(rtbgen PRIVATE ${REGULAR_FLAGS})
set_target_properties(rtbgen PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${BIN_DIR})

# rtbgenp (pawnful generator)
set(RTBGENP_SRCS
    ${SRC_DIR}/tbgenp.c
    ${SRC_DIR}/wincompat.c
    ${COMMON_SOURCES}
)
add_executable(rtbgenp ${RTBGENP_SRCS})
target_compile_definitions(rtbgenp PRIVATE ${REGULAR_FLAGS})
set_target_properties(rtbgenp PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${BIN_DIR})

# rtbver (pawnless verifier)
set(RTBVER_SRCS
    ${SRC_DIR}/tbver.c
    ${SRC_DIR}/decompress.c
    ${SRC_DIR}/threads.c
    ${SRC_DIR}/checksum.c
    ${SRC_DIR}/city-c.c
    ${SRC_DIR}/util.c
)
add_executable(rtbver ${RTBVER_SRCS})
target_compile_definitions(rtbver PRIVATE ${REGULAR_FLAGS})
set_target_properties(rtbver PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${BIN_DIR})

# rtbverp (pawnful verifier)
set(RTBVERP_SRCS
    ${SRC_DIR}/tbverp.c
    ${SRC_DIR}/decompress.c
    ${SRC_DIR}/threads.c
    ${SRC_DIR}/checksum.c
    ${SRC_DIR}/city-c.c
    ${SRC_DIR}/util.c
)
add_executable(rtbverp ${RTBVERP_SRCS})
target_compile_definitions(rtbverp PRIVATE ${REGULAR_FLAGS})
set_target_properties(rtbverp PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${BIN_DIR})

# tbcheck
set(TBCHECK_SRCS
    ${SRC_DIR}/tbcheck.c
    ${SRC_DIR}/threads.c
    ${SRC_DIR}/checksum.c
    ${SRC_DIR}/city-c.c
    ${SRC_DIR}/lz4.c
    ${SRC_DIR}/util.c
)
add_executable(tbcheck ${TBCHECK_SRCS})
target_compile_definitions(tbcheck PRIVATE ${REGULAR_FLAGS})
set_target_properties(tbcheck PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR})

# Regular target
add_custom_target(regular
    DEPENDS rtbgen rtbgenp rtbver rtbverp tbcheck
)

# ============================================
# ATOMIC CHESS - .atbw/.atbz
# ============================================

# atbgen (pawnless generator)
set(ATBGEN_SRCS
    ${SRC_DIR}/tbgen.c
    ${COMMON_SOURCES}
)
add_executable(atbgen ${ATBGEN_SRCS})
target_compile_definitions(atbgen PRIVATE ${ATOMIC_FLAGS})
set_target_properties(atbgen PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${BIN_DIR})

# atbgenp (pawnful generator)
set(ATBGENP_SRCS
    ${SRC_DIR}/tbgenp.c
    ${COMMON_SOURCES}
)
add_executable(atbgenp ${ATBGENP_SRCS})
target_compile_definitions(atbgenp PRIVATE ${ATOMIC_FLAGS})
set_target_properties(atbgenp PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${BIN_DIR})

# atbver (pawnless verifier)
set(ATBVER_SRCS
    ${SRC_DIR}/tbver.c
    ${SRC_DIR}/decompress.c
    ${SRC_DIR}/threads.c
    ${SRC_DIR}/checksum.c
    ${SRC_DIR}/city-c.c
    ${SRC_DIR}/util.c
)
add_executable(atbver ${ATBVER_SRCS})
target_compile_definitions(atbver PRIVATE ${ATOMIC_FLAGS})
set_target_properties(atbver PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${BIN_DIR})

# atbverp (pawnful verifier)
set(ATBVERP_SRCS
    ${SRC_DIR}/tbverp.c
    ${SRC_DIR}/decompress.c
    ${SRC_DIR}/threads.c
    ${SRC_DIR}/checksum.c
    ${SRC_DIR}/city-c.c
    ${SRC_DIR}/util.c
)
add_executable(atbverp ${ATBVERP_SRCS})
target_compile_definitions(atbverp PRIVATE ${ATOMIC_FLAGS})
set_target_properties(atbverp PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${BIN_DIR})

# Atomic target
add_custom_target(atomic
    DEPENDS atbgen atbgenp atbver atbverp tbcheck
)

# ============================================
# SUICIDE CHESS - .stbw/.stbz
# ============================================

# stbgen (pawnless generator)
set(STBGEN_SRCS
    ${SRC_DIR}/tbgen.c
    ${COMMON_SOURCES}
)
add_executable(stbgen ${STBGEN_SRCS})
target_compile_definitions(stbgen PRIVATE ${SUICIDE_FLAGS})
set_target_properties(stbgen PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${BIN_DIR})

# stbgenp (pawnful generator)
set(STBGENP_SRCS
    ${SRC_DIR}/tbgenp.c
    ${COMMON_SOURCES}
)
add_executable(stbgenp ${STBGENP_SRCS})
target_compile_definitions(stbgenp PRIVATE ${SUICIDE_FLAGS})
set_target_properties(stbgenp PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${BIN_DIR})

# stbver (pawnless verifier)
set(STBVER_SRCS
    ${SRC_DIR}/tbver.c
    ${SRC_DIR}/decompress.c
    ${SRC_DIR}/threads.c
    ${SRC_DIR}/checksum.c
    ${SRC_DIR}/city-c.c
    ${SRC_DIR}/util.c
)
add_executable(stbver ${STBVER_SRCS})
target_compile_definitions(stbver PRIVATE ${SUICIDE_FLAGS})
set_target_properties(stbver PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${BIN_DIR})

# stbverp (pawnful verifier)
set(STBVERP_SRCS
    ${SRC_DIR}/tbverp.c
    ${SRC_DIR}/decompress.c
    ${SRC_DIR}/threads.c
    ${SRC_DIR}/checksum.c
    ${SRC_DIR}/city-c.c
    ${SRC_DIR}/util.c
)
add_executable(stbverp ${STBVERP_SRCS})
target_compile_definitions(stbverp PRIVATE ${SUICIDE_FLAGS})
set_target_properties(stbverp PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${BIN_DIR})

# Suicide target
add_custom_target(suicide
    DEPENDS stbgen stbgenp stbver stbverp tbcheck
)

# ============================================
# GIVEAWAY CHESS - .gtbw/.gtbz
# (Must lose pieces, subset of SUICIDE)
# ============================================

add_executable(gtbgen ${SRC_DIR}/tbgen.c ${COMMON_SOURCES})
target_compile_definitions(gtbgen PRIVATE ${GIVEAWAY_FLAGS})
set_target_properties(gtbgen PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${BIN_DIR})

add_executable(gtbgenp ${SRC_DIR}/tbgenp.c ${COMMON_SOURCES})
target_compile_definitions(gtbgenp PRIVATE ${GIVEAWAY_FLAGS})
set_target_properties(gtbgenp PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${BIN_DIR})

# gtbver (pawnless verifier)
set(GTBVER_SRCS
    ${SRC_DIR}/tbver.c
    ${SRC_DIR}/decompress.c
    ${SRC_DIR}/threads.c
    ${SRC_DIR}/checksum.c
    ${SRC_DIR}/city-c.c
    ${SRC_DIR}/util.c
)
add_executable(gtbver ${GTBVER_SRCS})
target_compile_definitions(gtbver PRIVATE ${GIVEAWAY_FLAGS})
set_target_properties(gtbver PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${BIN_DIR})

# gtbverp (pawnful verifier)
set(GTBVERP_SRCS
    ${SRC_DIR}/tbverp.c
    ${SRC_DIR}/decompress.c
    ${SRC_DIR}/threads.c
    ${SRC_DIR}/checksum.c
    ${SRC_DIR}/city-c.c
    ${SRC_DIR}/util.c
)
add_executable(gtbverp ${GTBVERP_SRCS})
target_compile_definitions(gtbverp PRIVATE ${GIVEAWAY_FLAGS})
set_target_properties(gtbverp PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${BIN_DIR})

add_custom_target(giveaway
    DEPENDS gtbgen gtbgenp gtbver gtbverp tbcheck
)

# ============================================
# SHRATRANJ CHESS - .jtbw/.jtbz
# (Ancient chess variant with slower pieces)
# ============================================

# jtbgen (pawnless generator)
set(JTBGEN_SRCS
    ${SRC_DIR}/tbgen.c
    ${COMMON_SOURCES}
)
add_executable(jtbgen ${JTBGEN_SRCS})
target_compile_definitions(jtbgen PRIVATE ${SHATRANJ_FLAGS})
set_target_properties(jtbgen PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${BIN_DIR})

# jtbgenp (pawnful generator)
set(JTBGENP_SRCS
    ${SRC_DIR}/tbgenp.c
    ${COMMON_SOURCES}
)
add_executable(jtbgenp ${JTBGENP_SRCS})
target_compile_definitions(jtbgenp PRIVATE ${SHATRANJ_FLAGS})
set_target_properties(jtbgenp PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${BIN_DIR})

# jtbver (pawnless verifier)
set(JTBVER_SRCS
    ${SRC_DIR}/tbver.c
    ${SRC_DIR}/decompress.c
    ${SRC_DIR}/threads.c
    ${SRC_DIR}/checksum.c
    ${SRC_DIR}/city-c.c
    ${SRC_DIR}/util.c
)
add_executable(jtbver ${JTBVER_SRCS})
target_compile_definitions(jtbver PRIVATE ${SHATRANJ_FLAGS})
set_target_properties(jtbver PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${BIN_DIR})

# jtbverp (pawnful verifier)
set(JTBVERP_SRCS
    ${SRC_DIR}/tbverp.c
    ${SRC_DIR}/decompress.c
    ${SRC_DIR}/threads.c
    ${SRC_DIR}/checksum.c
    ${SRC_DIR}/city-c.c
    ${SRC_DIR}/util.c
)
add_executable(jtbverp ${JTBVERP_SRCS})
target_compile_definitions(jtbverp PRIVATE ${SHATRANJ_FLAGS})
set_target_properties(jtbverp PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${BIN_DIR})

# Shatranj target
add_custom_target(shatranj
    DEPENDS jtbgen jtbgenp jtbver jtbverp tbcheck
)

# ============================================
# LOSER CHESS - .ltbw/.ltbz
# (Loser variant, reuses giveaway/suicide code + LOSER define)
# ============================================
add_executable(ltbgen ${SRC_DIR}/tbgen.c ${COMMON_SOURCES})
target_compile_definitions(ltbgen PRIVATE ${LOSER_FLAGS})
set_target_properties(ltbgen PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${BIN_DIR})

add_executable(ltbgenp ${SRC_DIR}/tbgenp.c ${COMMON_SOURCES})
target_compile_definitions(ltbgenp PRIVATE ${LOSER_FLAGS})
set_target_properties(ltbgenp PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${BIN_DIR})

# ltbver (pawnless verifier)
set(LTBVER_SRCS
    ${SRC_DIR}/tbver.c
    ${SRC_DIR}/decompress.c
    ${SRC_DIR}/threads.c
    ${SRC_DIR}/checksum.c
    ${SRC_DIR}/city-c.c
    ${SRC_DIR}/util.c
)
add_executable(ltbver ${LTBVER_SRCS})
target_compile_definitions(ltbver PRIVATE ${LOSER_FLAGS})
set_target_properties(ltbver PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${BIN_DIR})

# ltbverp (pawnful verifier)
set(LTBVERP_SRCS
    ${SRC_DIR}/tbverp.c
    ${SRC_DIR}/decompress.c
    ${SRC_DIR}/threads.c
    ${SRC_DIR}/checksum.c
    ${SRC_DIR}/city-c.c
    ${SRC_DIR}/util.c
)
add_executable(ltbverp ${LTBVERP_SRCS})
target_compile_definitions(ltbverp PRIVATE ${LOSER_FLAGS})
set_target_properties(ltbverp PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${BIN_DIR})

add_custom_target(loser
    DEPENDS ltbgen ltbgenp ltbver ltbverp tbcheck
)

# ============================================
# Build all variants target
# ============================================
add_custom_target(build_all
    DEPENDS regular atomic suicide giveaway shatranj loser
)

# Installation
install(TARGETS rtbgen rtbgenp rtbver rtbverp tbcheck
        DESTINATION bin
        CONFIGURATIONS Release)

install(TARGETS atbgen atbgenp atbver atbverp
        DESTINATION bin
        CONFIGURATIONS Release)

install(TARGETS stbgen stbgenp
        DESTINATION bin
        CONFIGURATIONS Release)

install(TARGETS gtbgen gtbgenp
        DESTINATION bin
        CONFIGURATIONS Release)

install(TARGETS jtbgen jtbgenp jtbver jtbverp
        DESTINATION bin
        CONFIGURATIONS Release)

install(TARGETS ltbgen ltbgenp ltbver ltbverp
        DESTINATION bin
        CONFIGURATIONS Release)

# ============================================
# Build Summary
# ============================================
message(STATUS "")
message(STATUS "============================================")
message(STATUS "tb-1 Tablebase Generator Configuration")
message(STATUS "============================================")
message(STATUS "Build Type: ${CMAKE_BUILD_TYPE}")
message(STATUS "Compiler: ${CMAKE_C_COMPILER}")
message(STATUS "Attack Method: ${ATTACK_METHOD}")
if(USE_ZSTD)
    set(COMPRESSOR "ZSTD")
else()
    set(COMPRESSOR "LZ4")
endif()
message(STATUS "Compression: ${COMPRESSOR}")
message(STATUS "Max Pieces: ${MAX_TBPIECES}")
message(STATUS "Compression Threads: ${COMPRESSION_THREADS_COUNT}")
message(STATUS "============================================")
message(STATUS "")