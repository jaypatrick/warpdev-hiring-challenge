# Warp Hiring Challenge

## About
This is a programming challenge for candidates who are interested in applying to Warp. It's meant to be short and fun -- we highly encourage you to use Agent Mode in Warp to solve the challenge! There will be fields in the application for you to share your answer and a link to Warp Shared Block containing the command you used to solve the problem.

Participation in the challenge is optional. You can still submit an application without doing the hiring challenge.

Get started by reading the [challenge description](mission_challenge.md). Good luck!

## Solution

The challenge has been solved using both **AWK** and **Rust**!

**Answer:**
- Security Code: `XRT-421-ZQP`
- Mission Length: `1629 days`

### AWK Solution

Run the AWK solution with:

```bash
awk -f src/mars_mission_analyzer.awk data/space_missions.log
```

### Rust Solution

Run the Rust solution with:

```bash
# Build and run (first time)
cargo build --release
./target/release/mars-mission-analyzer data/space_missions.log

# Or use the convenience wrapper
./analyze-rust data/space_missions.log          # Unix/Linux/macOS
analyze-rust.bat data/space_missions.log        # Windows
```

**Performance Comparison:**
- Rust: ~0.12 seconds (2x faster)
- AWK: ~0.22 seconds

### Quick Start

**AWK Version:**
```bash
# Basic usage
awk -f src/mars_mission_analyzer.awk data/space_missions.log

# With timing (convenience wrapper)
./analyze              # Unix/Linux/macOS/WSL/Git Bash
analyze.bat            # Windows CMD/PowerShell

# Show help
awk -v help=1 -f src/mars_mission_analyzer.awk

# Verbose output with statistics
awk -v verbose=1 -f src/mars_mission_analyzer.awk data/space_missions.log

# Get top 5 longest missions
awk -v top=5 -f src/mars_mission_analyzer.awk data/space_missions.log

# Export as JSON
awk -v format=json -f src/mars_mission_analyzer.awk data/space_missions.log

# Export as CSV
awk -v format=csv -v top=10 -f src/mars_mission_analyzer.awk data/space_missions.log

# Benchmark performance
time awk -f src/mars_mission_analyzer.awk data/space_missions.log
```

**Rust Version:**
```bash
# Basic usage
./target/release/mars-mission-analyzer data/space_missions.log

# Show help
./target/release/mars-mission-analyzer --help

# Verbose output with statistics
./target/release/mars-mission-analyzer --verbose data/space_missions.log

# Get top 5 longest missions
./target/release/mars-mission-analyzer --top 5 data/space_missions.log

# Export as JSON
./target/release/mars-mission-analyzer --format json data/space_missions.log

# Export as CSV with top 10
./target/release/mars-mission-analyzer --format csv --top 10 data/space_missions.log

# Benchmark performance
time ./target/release/mars-mission-analyzer data/space_missions.log
```

### Features

#### Output Formats
- **Default**: Human-readable text output
- **JSON**: Structured data for programmatic use (`-v format=json`)
- **CSV**: Spreadsheet-compatible format (`-v format=csv`)

#### Advanced Options
- **Top N results**: Show multiple missions (`-v top=N`)
- **Verbose mode**: Detailed statistics and warnings (`-v verbose=1`)
- **Help**: Built-in usage documentation (`-v help=1`)

#### Robustness
- Portable AWK script (works on macOS/BSD and GNU awk)
- Comprehensive error handling and validation
- Validates data format and security code patterns (ABC-123-XYZ)
- Detailed statistics and error reporting
- Field count validation and type checking
- Proper exit codes for automation

#### Testing & CI/CD
- Comprehensive test suite in `tests/`
- Automated testing with GitHub Actions
- Cross-platform testing (macOS and Linux)

#### Performance
- **Rust**: Processes ~100K lines in ~0.12 seconds
  - Compiled binary with aggressive optimizations
  - Type-safe, memory-efficient processing
  - Built with LTO and single codegen unit
- **AWK**: Processes ~100K lines in ~0.22 seconds
  - Optimized single-pass processing
  - Early-exit optimization for non-Mars missions
  - Efficient text processing
- Built-in timing via `./analyze` and `./analyze-rust` wrappers

### Running Tests

**AWK Tests:**

*Platform-Agnostic (Recommended):*
```bash
# Works on all platforms - automatically detects OS
./test

# Or on Windows CMD
test.cmd
```

*Platform-Specific:*

Unix/Linux/macOS/WSL/Git Bash:
```bash
./tests/run_tests.sh
```

Windows CMD/PowerShell:
```cmd
tests\run_tests.bat
```

*Quick Manual Test:*
```bash
# Test with small dataset (works on all platforms)
awk -f src/mars_mission_analyzer.awk tests/test_data.log
```

**Rust Tests:**

```bash
# Run all tests (unit + integration)
cargo test

# Run tests in release mode
cargo test --release

# Run with verbose output
cargo test -- --nocapture

# Run specific test
cargo test test_mission_from_line_valid

# Run only unit tests
cargo test --lib

# Run only integration tests
cargo test --test integration_test
```

**Test Coverage:**
- **14 Unit Tests**: Test Mission struct parsing, validation, security code format, filtering logic, sorting
- **14 Integration Tests**: Test CLI arguments, file processing, output formats (JSON, CSV, default), error handling, edge cases
- All tests pass with 100% success rate

### Documentation

- [WARP.md](WARP.md) - Architecture notes and common commands
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Common issues and solutions
- [WINDOWS.md](WINDOWS.md) - Windows-specific installation and usage guide
- [mission_challenge.md](mission_challenge.md) - Original challenge description

### Project Structure

```
.
├── src/
│   ├── main.rs                    # Rust implementation
│   └── mars_mission_analyzer.awk  # AWK script to find longest Mars missions
├── data/
│   └── space_missions.log     # Full mission log (~10MB)
├── tests/
│   ├── test_data.log          # Test dataset
│   ├── integration_test.rs    # Rust integration tests
│   ├── run_tests.sh           # Unix test runner (AWK)
│   └── run_tests.bat          # Windows test runner (AWK)
├── .github/
│   └── workflows/
│       └── test.yml           # CI/CD configuration
├── Cargo.toml                 # Rust project configuration
├── test                       # Platform-agnostic test wrapper (Unix)
├── test.cmd                   # Platform-agnostic test wrapper (Windows)
├── analyze                    # AWK analysis with timing (Unix)
├── analyze.bat                # AWK analysis with timing (Windows)
├── analyze-rust               # Rust analysis with timing (Unix)
├── analyze-rust.bat           # Rust analysis with timing (Windows)
├── README.md                  # This file
├── WARP.md                    # Developer documentation
├── WINDOWS.md                 # Windows-specific guide
├── TROUBLESHOOTING.md         # Troubleshooting guide
└── mission_challenge.md       # Challenge description
```
