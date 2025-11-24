# Running on Windows

The AWK solution works on Windows with a few different approaches.

## Option 1: Windows Subsystem for Linux (WSL) - Recommended

WSL provides a full Linux environment on Windows and is the easiest way to run the solution.

### Setup
```bash
# Install WSL (PowerShell as Administrator)
wsl --install

# Or install Ubuntu specifically
wsl --install -d Ubuntu

# After restart, open Ubuntu and run
sudo apt-get update
sudo apt-get install gawk
```

### Usage
Once in WSL, use all commands exactly as documented:
```bash
awk -f src/mars_mission_analyzer.awk data/space_missions.log
./tests/run_tests.sh
```

## Option 2: Git Bash

Git Bash comes with AWK and works well for running the solution.

### Setup
1. Install [Git for Windows](https://git-scm.com/download/win)
2. Open Git Bash

### Usage
```bash
# Basic usage works the same
awk -f src/mars_mission_analyzer.awk data/space_missions.log

# Test with small dataset
awk -f src/mars_mission_analyzer.awk tests/test_data.log

# JSON output
awk -v format=json -f src/mars_mission_analyzer.awk data/space_missions.log

# Top 5 missions
awk -v top=5 -f src/mars_mission_analyzer.awk data/space_missions.log
```

### Limitations
- The shell test script (`run_tests.sh`) uses bash-specific features
- May need to run tests manually (see Manual Testing below)

## Option 3: Native Windows with gawk

Install AWK natively on Windows.

### Setup
1. **Using Chocolatey** (easiest):
   ```powershell
   # Install Chocolatey first: https://chocolatey.org/install
   choco install gawk
   ```

2. **Using Scoop**:
   ```powershell
   # Install Scoop first: https://scoop.sh/
   scoop install gawk
   ```

3. **Manual Installation**:
   - Download gawk for Windows from [GNU FTP](https://ftp.gnu.org/gnu/gawk/)
   - Extract and add to PATH

### Usage in PowerShell
```powershell
# Basic usage
gawk -f src/mars_mission_analyzer.awk data/space_missions.log

# With options
gawk -v format=json -f src/mars_mission_analyzer.awk data/space_missions.log
gawk -v top=5 -f src/mars_mission_analyzer.awk data/space_missions.log
```

### Usage in Command Prompt
```cmd
gawk -f src\mars_mission_analyzer.awk data/space_missions.log
gawk -v format=json -f src\mars_mission_analyzer.awk data/space_missions.log
```

## Option 4: Cygwin

Cygwin provides a Unix-like environment on Windows.

### Setup
1. Download and install [Cygwin](https://www.cygwin.com/)
2. During installation, select the `gawk` package
3. Open Cygwin terminal

### Usage
Works exactly like Linux:
```bash
awk -f src/mars_mission_analyzer.awk data/space_missions.log
./tests/run_tests.sh
```

## Platform-Agnostic Test Wrapper

The easiest way to run tests on any platform:

```bash
# In Git Bash, WSL, or any Unix-like shell
./test

# In Windows CMD or PowerShell
test.cmd
```

The wrapper automatically:
- Detects your operating system
- Checks for required tools (bash, gawk)
- Runs the appropriate test script
- Provides helpful error messages if tools are missing

## Manual Testing on Windows

If the automated test script doesn't work, test manually:

### PowerShell Testing
```powershell
# Test help
gawk -v help=1 -f src/mars_mission_analyzer.awk

# Test with small dataset
gawk -f src/mars_mission_analyzer.awk tests/test_data.log

# Verify output contains: STU-901-FGH

# Test JSON
gawk -v format=json -f src/mars_mission_analyzer.awk tests/test_data.log

# Test CSV
gawk -v format=csv -f src/mars_mission_analyzer.awk tests/test_data.log

# Test top N
gawk -v top=3 -f src/mars_mission_analyzer.awk tests/test_data.log

# Test with full data
gawk -f src/mars_mission_analyzer.awk data/space_missions.log
# Should output: XRT-421-ZQP and 1629 days
```

### Batch Script for Testing
Create `test.bat` with:
```batch
@echo off
echo Testing AWK solution...
echo.

echo Test 1: Basic usage with test data
gawk -f src\mars_mission_analyzer.awk tests\test_data.log
echo.

echo Test 2: JSON format
gawk -v format=json -f src\mars_mission_analyzer.awk tests\test_data.log
echo.

echo Test 3: Top 3 missions
gawk -v top=3 -f src\mars_mission_analyzer.awk tests\test_data.log
echo.

echo Test 4: Full dataset
gawk -f src\mars_mission_analyzer.awk data/space_missions.log
echo.

echo Tests complete!
```

Run with:
```cmd
test.bat
```

## Common Windows Issues

### Issue: "awk" is not recognized
**Solution**: Use `gawk` instead of `awk`, or add gawk to your PATH:
```powershell
# PowerShell - add to PATH permanently
$env:PATH += ";C:\Program Files\GnuWin32\bin"
[Environment]::SetEnvironmentVariable("PATH", $env:PATH, "User")
```

### Issue: Line ending issues (^M characters)
**Solution**: Convert line endings to Unix format:
```bash
# In WSL or Git Bash
dos2unix src/mars_mission_analyzer.awk tests/run_tests.sh

# Or using PowerShell
(Get-Content src\mars_mission_analyzer.awk) | Set-Content -NoNewline src\mars_mission_analyzer.awk
```

### Issue: Path separators
**Windows uses backslashes**: In PowerShell/CMD, use `\` instead of `/`:
```cmd
gawk -f src\mars_mission_analyzer.awk data/space_missions.log
```

**Git Bash uses forward slashes**: In Git Bash, use `/`:
```bash
awk -f src/mars_mission_analyzer.awk data/space_missions.log
```

### Issue: Test script won't run
**Solution**: Use Git Bash or WSL, or test manually using the PowerShell commands above.

## Recommended Setup for Windows Users

For the best experience:
1. **Primary**: Use WSL2 (Ubuntu) - full compatibility, all features work
2. **Alternative**: Use Git Bash - good compatibility, manual testing required
3. **Fallback**: Native gawk with PowerShell - works but requires manual testing

## File Compatibility

The AWK script (`src/mars_mission_analyzer.awk`) is fully compatible with Windows. The data file (`data/space_missions.log`) will work on any platform. Only the bash test script needs adaptation for Windows.

## Performance Notes

- **WSL**: Near-native Linux performance
- **Git Bash**: Good performance, slight overhead
- **Cygwin**: Slightly slower due to POSIX emulation
- **Native gawk**: Best performance on Windows

## Getting Help

If you encounter issues:
1. Check [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for common solutions
2. Ensure AWK/gawk is properly installed: `gawk --version`
3. Test with small dataset first: `gawk -f src/mars_mission_analyzer.awk tests/test_data.log`
4. Use verbose mode for debugging: `gawk -v verbose=1 -f src/mars_mission_analyzer.awk tests/test_data.log`
