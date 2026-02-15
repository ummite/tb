# Chess Tablebase Generator Project Guide

## Project Overview

This project is a generator for chess endgame databases ("tablebases") for up to 7 pieces. It produces compressed files that store win/draw/loss (WDL) and distance-to-zero (DTZ) information for chess positions, enabling chess engines to make optimal moves in endgame scenarios.

Key technologies include:
- C programming language
- GNU Make build system
- LZ4 or ZSTD compression libraries
- Multi-threading support for parallel processing
- Platform-specific optimizations (BMI2, Hyper, Magic square attacks)

The generator supports multiple chess variants including regular chess, atomic, suicide, and giveaway variants.

## Getting Started

### Prerequisites
- GCC compiler (or MinGW on Windows)
- ZSTD compression library and headers
- At least 16GB RAM (for 6-piece tables) or 1TB RAM (for 7-piece tables)
- x86-64 architecture with BMI2 support for optimal performance

### Installation
1. Clone the repository
2. Navigate to the `src/` directory
3. Run `make all` to build all components (requires ZSTD library)
4. The build produces executables: `rtbgen`, `rtbgenp`, `rtbver`, `rtbverp`, `tbcheck`

### Basic Usage
Generate tablebases:
```bash
# Generate pawnless tablebase
rtbgen KQRvKR

# Generate pawnful tablebase
rtbgenp KRPvKR
```

### Running Tests
The project includes verification tools:
- `rtbver` - Verify pawnless tablebases
- `rtbverp` - Verify pawnful tablebases
- `tbcheck` - Check integrity using embedded checksums

## Project Structure

```
.
├── README.md          # Project overview and documentation
├── src/               # Source code directory
│   ├── *.c            # C implementation files
│   ├── *.h            # Header files
│   ├── Makefile       # Build configuration
│   ├── run.pl         # Perl script for batch operations
│   └── run.py         # Python script for batch operations
├── .continue/         # Continue workspace files
│   └── rules/         # Project documentation
└── docs/              # Additional documentation (if any)
```

### Key Directories and Files

**src/** - Contains the core implementation:
- `rtbgen*` family: Pawnless tablebase generation and verification
- `rtbgenp*` family: Pawnful tablebase generation and verification  
- `tbcheck`: Integrity checking
- `Makefile` and variants: Build configuration for different chess variants
- `run.pl`/`run.py`: Scripts for batch operations

**src/Makefile** - Main build configuration:
- Selects attack generation method (BMI2, Hyper, Magic)
- Configures compiler flags and optimization
- Sets compression libraries (ZSTD/LZ4)
- Defines compilation parameters

## Development Workflow

### Coding Standards
- C programming with C11 standard
- Multi-threaded implementation using pthreads
- Platform-specific optimizations (BMI2, SSE3, Magic)
- Bitboard-based chess position representation
- Header guards and proper modular design

### Testing Approach
- Verification using dedicated `rtbver`/`rtbverp` programs
- Integrity checking with `tbcheck` against embedded checksums
- Statistics collection with `--stats` flag
- Cross-platform testing on Linux and Windows (MinGW)

### Build and Deployment
- Build using GNU Make
- Support for ZSTD or LZ4 compression
- Thread configuration for optimal performance
- Multi-variant support (regular, atomic, suicide, giveaway)

### Contribution Guidelines
1. Make changes to source files in `src/`
2. Ensure builds successfully with `make all`
3. Test with the provided verification tools
4. Update the documentation as needed

## Key Concepts

### Chess Variants
The system supports multiple chess variants:
- **Regular**: Standard chess rules
- **Atomic**: Captures explode surrounding pieces
- **Suicide**: Must capture if possible, else move
- **Giveaway**: Opposite of suicide, must lose pieces if possible

### Data Structures
- **bitboard**: 64-bit unsigned integer for board representations  
- **Move**: 16-bit unsigned integer encoding moves
- **dtz_map**: Maps positions to distance-to-zero values
- **TBEntry**: Tablebase entry structure for storage

### Tablebase Files
Each tablebase generates two files:
- `.rtbw`: Win/Draw/Loss information (two-sided)
- `.rtbz`: Distance-to-zero information (single-sided)

## Common Tasks

### Generating Tablebases
```bash
# Generate standard 6-piece tablebase
rtbgen KQvK

# Generate with multiple threads
rtbgen -t 8 KQvK

# Generate only WDL file
rtbgen -w KQvK

# Generate with stats
rtbgen -s KQvK
```

### Verifying Tablebases
```bash
# Verify generated tablebase
rtbver KQvK

# Verify with multiple threads
rtbver -t 8 KQvK

# Log verification results
rtbver -l KQvK
```

### Checking Integrity
```bash
# Check tablebase file integrity
tbcheck KQvK.rtbw KQvK.rtbz

# Print embedded checksums 
tbcheck -p KQvK.rtbw
```

### Using Scripts
```bash
# Generate all tables
python run.py --generate

# Generate with constraints
python run.py --generate --min 3 --max 5

# Verify all tables
python run.py --verify
```

## Troubleshooting

### Memory Issues
- For 6-piece tables: Minimum 16GB RAM required
- Use `--disk` option to reduce memory usage during compression
- Increasing RAM to 24GB+ allows generation without --disk flag

### Build Errors
- Ensure ZSTD library and headers are installed
- Verify compiler supports required flags (-march=native, -D_GNU_SOURCE)
- Check that `make all` runs successfully

### Performance Problems
- Use appropriate thread count (`-t` flag) matching available cores
- Enable compression threads via `COMPRESSION_THREADS` in Makefile
- For pawnful tables, enable `USE_POPCNT` compilation flag

## References

- **Primary Documentation**: README.md included in project root
- **Probing Code**: https://github.com/syzygy1/probetool
- **Technical Details**: http://kirill-kryukov.com/chess/tablebases-online/
- **Chess Variants**: Atomic, Suicide, Giveaway documentation
- **Licenses**: GNU GPL v2 for source code, BSD for lz4, CityHash, and c11threads
- **Build Information**: Makefile configurations and compiler flags