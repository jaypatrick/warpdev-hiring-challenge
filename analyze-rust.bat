@echo off
REM Wrapper script to run the Rust Mars mission analyzer with timing

REM Build if not already built
if not exist "target\release\mars-mission-analyzer.exe" (
    echo Building Rust analyzer (first time only)...
    cargo build --release
    echo.
)

REM Run with timing
echo Running Rust Mars Mission Analyzer...
echo ======================================
powershell -Command "Measure-Command { .\target\release\mars-mission-analyzer.exe %* | Out-Default } | Select-Object -ExpandProperty TotalSeconds | ForEach-Object { Write-Host \"Execution time: $_ seconds\" }"
