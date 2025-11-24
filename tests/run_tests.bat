@echo off
REM Test runner for AWK solution on Windows
REM Usage: tests\run_tests.bat

setlocal enabledelayedexpansion

set TESTS_PASSED=0
set TESTS_FAILED=0

echo ================================
echo Running AWK Solution Tests
echo ================================
echo.

REM Test 1: Help output
echo Testing: Help flag displays usage...
gawk -v help=1 -f src\mars_mission_analyzer.awk >nul 2>&1
if !errorlevel! equ 0 (
    echo [PASSED]
    set /a TESTS_PASSED+=1
) else (
    echo [FAILED]
    set /a TESTS_FAILED+=1
)

REM Test 2: Default output with test data
echo Testing: Default output format...
gawk -f src\mars_mission_analyzer.awk tests\test_data.log | findstr "STU-901-FGH" >nul
if !errorlevel! equ 0 (
    echo [PASSED]
    set /a TESTS_PASSED+=1
) else (
    echo [FAILED]
    set /a TESTS_FAILED+=1
)

REM Test 3: JSON output
echo Testing: JSON output format...
gawk -v format=json -f src\mars_mission_analyzer.awk tests\test_data.log | findstr "security_code" >nul
if !errorlevel! equ 0 (
    echo [PASSED]
    set /a TESTS_PASSED+=1
) else (
    echo [FAILED]
    set /a TESTS_FAILED+=1
)

REM Test 4: CSV output
echo Testing: CSV output format...
gawk -v format=csv -f src\mars_mission_analyzer.awk tests\test_data.log | findstr "Mission ID" >nul
if !errorlevel! equ 0 (
    echo [PASSED]
    set /a TESTS_PASSED+=1
) else (
    echo [FAILED]
    set /a TESTS_FAILED+=1
)

REM Test 5: Top N missions
echo Testing: Top 3 missions...
gawk -v top=3 -f src\mars_mission_analyzer.awk tests\test_data.log | find /c "Rank #" >nul
if !errorlevel! equ 0 (
    echo [PASSED]
    set /a TESTS_PASSED+=1
) else (
    echo [FAILED]
    set /a TESTS_FAILED+=1
)

REM Test 6: Full data file (if exists)
if exist data\space_missions.log (
    echo Testing: Full data file - longest mission...
    gawk -f src\mars_mission_analyzer.awk data\space_missions.log | findstr "XRT-421-ZQP" >nul
    if !errorlevel! equ 0 (
        echo [PASSED]
        set /a TESTS_PASSED+=1
    ) else (
        echo [FAILED]
        set /a TESTS_FAILED+=1
    )
    
    echo Testing: Full data file - JSON format...
    gawk -v format=json -f src\mars_mission_analyzer.awk data\space_missions.log | findstr "1629" >nul
    if !errorlevel! equ 0 (
        echo [PASSED]
        set /a TESTS_PASSED+=1
    ) else (
        echo [FAILED]
        set /a TESTS_FAILED+=1
    )
)

REM Test 7: Verbose mode
echo Testing: Verbose mode statistics...
gawk -v verbose=1 -f src\mars_mission_analyzer.awk tests\test_data.log 2>&1 | findstr "Processing Statistics" >nul
if !errorlevel! equ 0 (
    echo [PASSED]
    set /a TESTS_PASSED+=1
) else (
    echo [FAILED]
    set /a TESTS_FAILED+=1
)

echo.
echo ================================
echo Tests Passed: !TESTS_PASSED!
echo Tests Failed: !TESTS_FAILED!
echo ================================

if !TESTS_FAILED! equ 0 (
    echo All tests passed!
    exit /b 0
) else (
    echo Some tests failed.
    exit /b 1
)
