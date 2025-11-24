# Troubleshooting Guide

This guide helps you resolve common issues when running the AWK solution for the space mission log analysis challenge.

## Common Issues

### 1. "No such file or directory" Error

**Problem:** You get an error like `awk: can't open file src/mars_mission_analyzer.awk`

**Solution:**
- Make sure you're running the command from the project root directory
- Verify the file exists: `ls -la src/mars_mission_analyzer.awk`
- Use the correct path: `awk -f src/mars_mission_analyzer.awk space_missions.log`

### 2. "Permission denied" Error

**Problem:** The test script won't execute

**Solution:**
```bash
chmod +x tests/run_tests.sh
./tests/run_tests.sh
```

### 3. No Output or Hanging

**Problem:** The script runs but produces no output or appears to hang

**Possible Causes:**
1. **No input file specified**: Make sure to provide the log file
   ```bash
   awk -f src/mars_mission_analyzer.awk space_missions.log
   ```

2. **Reading from stdin**: If you don't specify a file, AWK waits for input from stdin
   - Press `Ctrl+D` to send EOF
   - Or provide a file as argument

3. **Very large file**: The full dataset takes time to process (~10MB file with 100k+ lines)
   - Be patient, it should complete in a few seconds
   - Use verbose mode to see progress: `awk -v verbose=1 -f src/mars_mission_analyzer.awk space_missions.log`

### 4. "ERROR: No valid completed Mars missions found"

**Problem:** The script reports no Mars missions were found

**Possible Causes:**
1. **Wrong file**: Make sure you're using the correct log file
   ```bash
   ls -lh space_missions.log  # Should be ~10MB
   ```

2. **Corrupted file**: The log file might be incomplete or corrupted
   - Re-download or re-extract the file
   - Check file size: should be approximately 10,151,813 bytes

3. **Using test data**: If you're using `tests/test_data.log`, it only has a few missions
   ```bash
   # This should work
   awk -f src/mars_mission_analyzer.awk tests/test_data.log
   ```

### 5. AWK Version Compatibility Issues

**Problem:** Script fails with syntax errors on your system

**Solution:**
The script is designed to be portable across AWK implementations:
- ✅ Works on macOS (BSD awk)
- ✅ Works on Linux (gawk)
- ✅ Works on most Unix systems

If you encounter issues:
```bash
# Check your AWK version
awk --version  # GNU awk (gawk)
awk -W version # Some BSD awk versions

# Try with gawk explicitly (if installed)
gawk -f src/mars_mission_analyzer.awk space_missions.log
```

### 6. JSON Output is Invalid

**Problem:** JSON parser complains about the output

**Solution:**
The JSON output is valid JSON. Common issues:
1. **Stderr mixed with stdout**: Redirect stderr to separate output
   ```bash
   awk -v format=json -f src/mars_mission_analyzer.awk space_missions.log 2>/dev/null
   ```

2. **Partial output**: Make sure the command completes successfully
   ```bash
   awk -v format=json -f src/mars_mission_analyzer.awk space_missions.log > output.json
   echo $?  # Should be 0 (success)
   ```

### 7. Tests Failing

**Problem:** `./tests/run_tests.sh` reports failures

**Debugging Steps:**
1. Run tests with more verbosity:
   ```bash
   bash -x ./tests/run_tests.sh
   ```

2. Test individual components:
   ```bash
   # Test help
   awk -v help=1 -f src/mars_mission_analyzer.awk
   
   # Test with small dataset
   awk -f src/mars_mission_analyzer.awk tests/test_data.log
   
   # Test JSON
   awk -v format=json -f src/mars_mission_analyzer.awk tests/test_data.log
   ```

3. Check AWK installation:
   ```bash
   which awk
   awk --version || awk -W version
   ```

### 8. Wrong Security Code or Duration

**Problem:** The output doesn't match expected values

**Expected Output:**
```
Security Code: XRT-421-ZQP
Mission Length: 1629 days
```

**Verification:**
```bash
# Verify with verbose mode
awk -v verbose=1 -f src/mars_mission_analyzer.awk space_missions.log

# Should show:
# - Found at line: 5448
# - Duration (days): 1629
# - Security Code: XRT-421-ZQP
```

**If different:**
1. Check if file is the correct version
2. Verify file hasn't been modified
3. Check for sorting issues with top-N feature:
   ```bash
   awk -v top=5 -f src/mars_mission_analyzer.awk space_missions.log
   ```

### 9. Performance Issues

**Problem:** Script is very slow

**Optimization Tips:**
1. **Disable verbose mode** for production use:
   ```bash
   awk -f src/mars_mission_analyzer.awk space_missions.log  # Fast
   awk -v verbose=1 -f src/mars_mission_analyzer.awk space_missions.log  # Slower
   ```

2. **Limit top-N results**:
   ```bash
   awk -v top=10 -f src/mars_mission_analyzer.awk space_missions.log
   ```

3. **Use appropriate AWK**: gawk is generally faster than BSD awk for large files

### 10. Character Encoding Issues

**Problem:** Strange characters in output

**Solution:**
The log file uses UTF-8 encoding:
```bash
file -I space_missions.log  # Should show charset=utf-8

# If needed, convert:
iconv -f ISO-8859-1 -t UTF-8 space_missions.log > space_missions_utf8.log
```

## Getting More Help

### Enable Verbose Mode
```bash
awk -v verbose=1 -f src/mars_mission_analyzer.awk space_missions.log 2>&1 | less
```

This shows:
- Processing statistics
- Number of lines processed
- Mars missions found
- Errors and warnings
- Line numbers with issues

### View Full Record
```bash
awk -v verbose=1 -f src/mars_mission_analyzer.awk space_missions.log | grep "Full Record"
```

### Check Specific Features
```bash
# Help text
awk -v help=1 -f src/mars_mission_analyzer.awk

# Top 5 missions  
awk -v top=5 -f src/mars_mission_analyzer.awk space_missions.log

# JSON output
awk -v format=json -f src/mars_mission_analyzer.awk space_missions.log | jq .

# CSV output
awk -v format=csv -v top=10 -f src/mars_mission_analyzer.awk space_missions.log | column -t -s,
```

## Still Having Issues?

1. Check the [WARP.md](WARP.md) file for detailed architecture notes
2. Review the [README.md](README.md) for setup instructions
3. Run the test suite: `./tests/run_tests.sh`
4. Verify your environment meets requirements (AWK available, proper file permissions)

## System Requirements

- AWK (any standard implementation: gawk, BSD awk, mawk)
- Bash (for running tests on Unix/Linux/macOS)
- ~10MB disk space for the log file
- Unix-like environment (Linux, macOS, WSL on Windows)

## Windows Users

For Windows-specific instructions, see [WINDOWS.md](WINDOWS.md) which covers:
- WSL installation and setup
- Git Bash usage
- Native Windows with gawk
- Batch script for testing
- Common Windows-specific issues
