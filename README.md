# Warp Hiring Challenge

## About
This is a programming challenge for candidates who are interested in applying to Warp. It's meant to be short and fun -- we highly encourage you to use Agent Mode in Warp to solve the challenge! There will be fields in the application for you to share your answer and a link to Warp Shared Block containing the command you used to solve the problem.

Participation in the challenge is optional. You can still submit an application without doing the hiring challenge.

Get started by reading the [challenge description](mission_challenge.md). Good luck!

## Solution

The challenge has been solved using AWK! Run the solution with:

```bash
awk -f src/mars_mission_analyzer.awk data/space_missions.log
```

**Answer:**
- Security Code: `XRT-421-ZQP`
- Mission Length: `1629 days`

### Quick Start

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
- Optimized AWK script processes ~100K lines in < 1 second
- Early-exit optimization for non-Mars missions
- Efficient single-pass processing
- Built-in timing via `./analyze` wrapper

### Running Tests

**Platform-Agnostic (Recommended):**
```bash
# Works on all platforms - automatically detects OS
./test

# Or on Windows CMD
test.cmd
```

**Platform-Specific:**

*Unix/Linux/macOS/WSL/Git Bash:*
```bash
./tests/run_tests.sh
```

*Windows CMD/PowerShell:*
```cmd
tests\run_tests.bat
```

**Quick Manual Test:**
```bash
# Test with small dataset (works on all platforms)
awk -f src/mars_mission_analyzer.awk tests/test_data.log
```

### Documentation

- [WARP.md](WARP.md) - Architecture notes and common commands
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Common issues and solutions
- [WINDOWS.md](WINDOWS.md) - Windows-specific installation and usage guide
- [mission_challenge.md](mission_challenge.md) - Original challenge description

### Project Structure

```
.
├── src/
│   └── mars_mission_analyzer.awk  # AWK script to find longest Mars missions
├── data/
│   └── space_missions.log     # Full mission log (~10MB)
├── tests/
│   ├── test_data.log          # Test dataset
│   ├── run_tests.sh           # Unix test runner
│   └── run_tests.bat          # Windows test runner
├── .github/
│   └── workflows/
│       └── test.yml           # CI/CD configuration
├── test                       # Platform-agnostic test wrapper (Unix)
├── test.cmd                   # Platform-agnostic test wrapper (Windows)
├── analyze                    # Analysis with timing (Unix)
├── analyze.bat                # Analysis with timing (Windows)
├── README.md                  # This file
├── WARP.md                    # Developer documentation
├── WINDOWS.md                 # Windows-specific guide
├── TROUBLESHOOTING.md         # Troubleshooting guide
└── mission_challenge.md       # Challenge description
```
