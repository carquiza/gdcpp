@echo off
setlocal

cd /d "%~dp0.."

set "MODE=%~1"
if "%MODE%"=="" set "MODE=debug"

if "%MODE%"=="debug" goto :run_debug
if "%MODE%"=="release" goto :run_release
echo ERROR: Unknown mode '%MODE%'. Use: debug or release
goto :fail

:run_debug
:: Find Godot binary
set "GODOT="
if defined GODOT_BIN if exist "%GODOT_BIN%" set "GODOT=%GODOT_BIN%"

if "%GODOT%"=="" if defined GODOT_SOURCE (
    for %%f in ("%GODOT_SOURCE%\bin\godot*editor*.exe") do set "GODOT=%%f"
)

if "%GODOT%"=="" (
    echo ERROR: Cannot find Godot binary.
    echo   Set GODOT_BIN to the Godot editor executable,
    echo   or set GODOT_SOURCE with an editor build in bin\.
    goto :fail
)

echo === Running debug with: %GODOT% ===
"%GODOT%" --path "%cd%\project"
goto :end

:run_release
set "BIN="
for %%f in ("build-windows\release\godot.windows.template_release*.exe") do set "BIN=%%f"

if "%BIN%"=="" (
    echo ERROR: No release binary found in build-windows\release\
    echo   Run 'scripts\build.bat release' first.
    goto :fail
)

:: Remove extension_list.cfg — release has classes baked in, no GDExtension needed
if exist "project\.godot\extension_list.cfg" del /q "project\.godot\extension_list.cfg"
:: Ensure empty script cache exists to avoid errors
call :setup_godot_dir

echo === Running release: %BIN% ===
"%BIN%"
goto :end

:end
pause
exit /b 0

:setup_godot_dir
if not exist "project\.godot" mkdir "project\.godot"
if not exist "project\.godot\global_script_class_cache.cfg" (
    echo [^"^"]> "project\.godot\global_script_class_cache.cfg"
    echo.>> "project\.godot\global_script_class_cache.cfg"
    echo list=[]>> "project\.godot\global_script_class_cache.cfg"
)
goto :eof

:fail
echo.
echo === RUN FAILED ===
pause
exit /b 1
