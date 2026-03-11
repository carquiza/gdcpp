@echo off
setlocal

cd /d "%~dp0.."

set "MODE=%~1"
set "PLATFORM=%~2"

if "%MODE%"=="" set "MODE=debug"
if "%PLATFORM%"=="" set "PLATFORM=windows"

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
if "%PLATFORM%"=="web" goto :run_release_web

set "BIN=build-windows\release\godot.windows.template_release.x86_64.exe"

if not exist "%BIN%" (
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

:run_release_web
set "WEB_DIR=build-web\release"

if not exist "%WEB_DIR%\index.html" (
    echo ERROR: No web release build found in %WEB_DIR%\
    echo   Run 'scripts\build.bat release web' first.
    goto :fail
)

echo === Serving web release on http://localhost:8060 ===
echo Press Ctrl+C to stop the server.
python -m http.server 8060 --directory "%WEB_DIR%"
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
