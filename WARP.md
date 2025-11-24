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

### Run the AWK solution
```bash
awk -F'|' -f src/solution.awk space_missions.log
```

### Run inline AWK (from solution.awk)
```bash
awk -F'|' 'BEGIN { IGNORECASE = 1; dest = "mars"; stat = "completed"; max = -inf } function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s } { destination = trim($3); status = trim($4); duration = trim($6); if (destination ~ dest && status ~ stat) { val = $6 + 0; if (val > max) { max = val; max_line = $0 } } } END { if (max == -inf) { print "No matches found." } else { print "Max value:", max; print "Row:", max_line } }' space_missions.log
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
head -100 space_missions.log | awk -F'|' -f src/solution.awk

# Extract just security codes from completed Mars missions
awk -F'|' 'NR > 6 && $3 ~ /Mars/ && $4 ~ /Completed/ { gsub(/^[ \t]+|[ \t]+$/, "", $8); print $8 }' space_missions.log

# Show all completed Mars missions with duration
awk -F'|' 'NR > 6 && $3 ~ /Mars/ && $4 ~ /Completed/ { print $0 }' space_missions.log
```

## Architecture Notes

### AWK Solution Approach
The solution in `src/solution.awk` uses:
- Field separator `-F'|'` to split pipe-delimited data
- `IGNORECASE = 1` for case-insensitive matching
- `trim()` function to handle inconsistent whitespace
- Pattern matching with `~` operator for destination and status
- Tracking maximum duration value and corresponding line
- Type coercion (`$6 + 0`) to convert string to number

### Key Challenges
1. **Whitespace handling**: Fields have variable leading/trailing spaces requiring the trim function
2. **Header lines**: First 6 lines contain metadata and must be skipped (handled by pattern matching)
3. **Type conversion**: Duration field is string by default, needs numeric conversion for comparison
4. **Case sensitivity**: Destinations/statuses may vary in case, requiring IGNORECASE flag

## Challenge Requirements
From `mission_challenge.md`:
- Find the **longest successful Mars mission**
- Criteria: Destination = "Mars", Status = "Completed"
- Extract the security code (format: ABC-123-XYZ)
- Submit security code as the answer
