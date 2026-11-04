@echo off
setlocal
cd /d "%~dp0"
set "GODOT_ENGINE=%~dp0..\Godot_v4.7.2-stable_win64.exe"
if not exist "%GODOT_ENGINE%" (
    echo Godot engine missing: "%GODOT_ENGINE%"
    pause
    exit /b 1
)
if not exist "%~dp0.godot" mkdir "%~dp0.godot"
echo Preparing game resources, please wait...
"%GODOT_ENGINE%" --headless --editor --path "%~dp0." --import --log-file "%~dp0.godot\startup-import.log" > "%~dp0.godot\startup-import-console.log" 2>&1
if errorlevel 1 goto import_failed
findstr /c:"SCRIPT ERROR:" /c:"ERROR:" "%~dp0.godot\startup-import-console.log" | findstr /v /c:"Failed to read the root certificate store" >nul
if not errorlevel 1 goto import_failed
start "" "%~dp0..\Godot_v4.7.2-stable_win64.exe" --path "%~dp0."
exit /b 0

:import_failed
echo Resource import failed. See the log below:
type "%~dp0.godot\startup-import-console.log"
pause
exit /b 1
