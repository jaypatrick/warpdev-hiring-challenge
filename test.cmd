@echo off
REM Platform-agnostic test runner wrapper for Windows CMD
REM Automatically runs appropriate test script
REM Usage: test.cmd or just: test

REM Check if running in Git Bash/WSL by checking for bash
where bash >nul 2>&1
if %errorlevel% equ 0 (
    echo Detected bash - using Unix-style test script...
    bash -c "./tests/run_tests.sh"
    exit /b %errorlevel%
)

REM Check if gawk is available
where gawk >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: gawk not found in PATH
    echo.
    echo Please install gawk using one of these methods:
    echo   - Chocolatey: choco install gawk
    echo   - Scoop: scoop install gawk
    echo   - WSL: wsl --install
    echo.
    echo Or see WINDOWS.md for detailed instructions
    exit /b 1
)

REM Run Windows batch test script
echo Running Windows test script...
call tests\run_tests.bat
exit /b %errorlevel%
