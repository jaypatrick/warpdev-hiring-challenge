# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Repository Overview
This is a Warp hiring challenge repository focused on log file analysis using AWK. The challenge involves parsing `space_missions.log` to find the longest successful Mars mission and extract its security code.

## Key Files
- `space_missions.log` - Large (~10MB) pipe-delimited log file containing space mission data from 2030-2070
- `mission_challenge.md` - Complete challenge description and requirements
- `src/solution.awk` - AWK script solution
- `README.md` - Brief overview and getting started instructions

## Data Format
The log file contains pipe-delimited fields with inconsistent spacing:
```
Date | Mission ID | Destination | Status | Crew Size | Duration (days) | Success Rate | Security Code
```

Important notes:
- Comment lines start with `#` (should be ignored)
- Field separators have variable whitespace
- Only "Completed" status missions are relevant
- Duration is in days (field 6)
- Security codes follow format: ABC-123-XYZ (field 8)

## Common Commands

### Basic Usage
```bash
# Standard output (security code and mission length)
awk -f src/solution.awk space_missions.log

# Get help
awk -v help=1 -f src/solution.awk

# Verbose output (includes statistics, warnings, and full record)
awk -v verbose=1 -f src/solution.awk space_missions.log
```

### Expected Output
```
Security Code: XRT-421-ZQP
Mission Length: 1629 days
```

### Advanced Features

#### Multiple Output Formats
```bash
# JSON output
awk -v format=json -f src/solution.awk space_missions.log

# JSON with formatting (requires jq)
awk -v format=json -f src/solution.awk space_missions.log | jq .

# CSV output
awk -v format=csv -f src/solution.awk space_missions.log

# CSV with top 10 missions
awk -v format=csv -v top=10 -f src/solution.awk space_missions.log
```

#### Top N Missions
```bash
# Get top 5 longest missions
awk -v top=5 -f src/solution.awk space_missions.log

# Get all missions (up to 975 valid completed Mars missions)
awk -v top=999 -f src/solution.awk space_missions.log
```

#### Combining Options
```bash
# Top 10 as JSON with verbose stats
awk -v format=json -v top=10 -v verbose=1 -f src/solution.awk space_missions.log

# Top 20 as CSV
awk -v format=csv -v top=20 -f src/solution.awk space_missions.log > results.csv
```

### Explore the log file structure
```bash
# View header and format information
head -10 space_missions.log

# Count total missions
wc -l space_missions.log

# View unique destinations
awk -F'|' 'NR > 6 { gsub(/^[ \t]+|[ \t]+$/, "", $3); print $3 }' space_missions.log | sort -u

# View unique statuses
awk -F'|' 'NR > 6 { gsub(/^[ \t]+|[ \t]+$/, "", $4); print $4 }' space_missions.log | sort -u

# Count Mars missions by status
awk -F'|' 'NR > 6 && $3 ~ /Mars/ { gsub(/^[ \t]+|[ \t]+$/, "", $4); print $4 }' space_missions.log | sort | uniq -c
```

### Validate and debug AWK scripts
```bash
# Test with first 100 lines
head -100 space_missions.log | awk -f src/solution.awk

# Extract just security codes from completed Mars missions
awk -F'|' 'NR > 6 && $3 ~ /Mars/ && $4 ~ /Completed/ { gsub(/^[ \t]+|[ \t]+$/, "", $8); print $8 }' space_missions.log

# Show all completed Mars missions with duration
awk -F'|' 'NR > 6 && $3 ~ /Mars/ && $4 ~ /Completed/ { print $0 }' space_missions.log
```

## Testing

### Run Test Suite
```bash
# Platform-agnostic (recommended) - auto-detects OS
./test

# Or platform-specific:
./tests/run_tests.sh              # Unix/Linux/macOS/WSL
tests\run_tests.bat               # Windows CMD

# Test with small dataset
awk -f src/solution.awk tests/test_data.log

# Expected result from test data
# Security Code: STU-901-FGH
# Mission Length: 900 days
```

### Manual Testing
```bash
# Test each output format
awk -f src/solution.awk tests/test_data.log
awk -v format=json -f src/solution.awk tests/test_data.log
awk -v format=csv -f src/solution.awk tests/test_data.log

# Test top N feature
awk -v top=3 -f src/solution.awk tests/test_data.log

# Test verbose mode
awk -v verbose=1 -f src/solution.awk tests/test_data.log

# Test error handling
echo "" | awk -f src/solution.awk  # Should exit with error
```

### CI/CD

GitHub Actions automatically runs tests on:
- Every push to `main` or `develop` branches
- Every pull request to `main`
- Manual workflow dispatch

Tests run on:
- Ubuntu (latest) with GNU awk
- macOS (latest) with BSD awk

Workflow file: `.github/workflows/test.yml`

## Architecture Notes

### AWK Solution Approach
The solution in `src/solution.awk` uses:
- Field separator `FS = "|"` to split pipe-delimited data
- `tolower()` function for portable case-insensitive matching (works on macOS/BSD awk)
- `trim()` function to handle inconsistent whitespace
- Pattern matching to filter Mars missions with "Completed" status
- Tracking maximum duration value and corresponding line
- Type coercion (`duration + 0`) to convert string to number
- Security code format validation (ABC-123-XYZ pattern)

### Error Handling Features
1. **Input Validation**:
   - Verifies minimum 8 fields per data line
   - Validates duration is a positive number
   - Validates security code format using regex pattern

2. **Statistics Tracking**:
   - Counts total lines, data lines, Mars missions, and completed missions
   - Tracks errors/warnings during processing
   - Reports line number where result was found

3. **Error Reporting**:
   - Specific error messages for different failure scenarios
   - Line-by-line warnings in verbose mode
   - All errors written to stderr, results to stdout

4. **Exit Codes**:
   - `0` = Success (answer found)
   - `1` = Failure (no valid Mars missions found)

### Key Challenges
1. **Whitespace handling**: Fields have variable leading/trailing spaces requiring the trim function
2. **Header lines**: First 6 lines contain metadata and must be skipped (handled by pattern matching)
3. **Type conversion**: Duration field is string by default, needs numeric conversion for comparison
4. **Case sensitivity**: Destinations/statuses may vary in case, using `tolower()` for portability
5. **Data validation**: Some lines have invalid formats, requiring field count and format validation
6. **Portability**: macOS awk doesn't support `IGNORECASE`, use `tolower()` instead

## Challenge Requirements
From `mission_challenge.md`:
- Find the **longest successful Mars mission**
- Criteria: Destination = "Mars", Status = "Completed"
- Extract the security code (format: ABC-123-XYZ)
- Submit security code as the answer
