@echo off
REM Convenience wrapper to run mars_mission_analyzer.awk with timing (Windows)
REM Usage: analyze.bat [options] [datafile]

setlocal enabledelayedexpansion

REM Check for help
if "%1"=="-h" goto :help
if "%1"=="--help" goto :help
if "%1"=="/?" goto :help

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

REM Default data file
set DATAFILE=data\space_missions.log

REM Find data file in arguments
for %%a in (%*) do (
    if exist "%%a" (
        set DATAFILE=%%a
    )
)

REM Check if data file exists
if not exist "%DATAFILE%" (
    echo Error: Data file not found: %DATAFILE%
    exit /b 1
)

REM Run with timing
echo Analyzing: %DATAFILE%
echo ================================
powershell -Command "Measure-Command { gawk %* -f src\mars_mission_analyzer.awk '%DATAFILE%' } | Select-Object TotalSeconds"
gawk %* -f src\mars_mission_analyzer.awk "%DATAFILE%"
exit /b %errorlevel%

:help
echo Mars Mission Analyzer - Convenience wrapper with timing
echo Usage: analyze.bat [AWK_OPTIONS] [datafile]
echo.
echo Examples:
echo   analyze.bat                          # Analyze with timing
echo   analyze.bat -v verbose=1             # Verbose output with timing
echo   analyze.bat -v format=json           # JSON output with timing
echo   analyze.bat -v top=5                 # Top 5 missions with timing
echo   analyze.bat tests\test_data.log      # Analyze test data
echo.
echo For more AWK options, run:
echo   gawk -v help=1 -f src\mars_mission_analyzer.awk
exit /b 0
