@echo off
setlocal

cd /d "%~dp0.."

set "MODE=%~1"
set "PLATFORM=%~2"

:: Show usage
if "%MODE%"=="--help" goto :usage
if "%MODE%"=="-h" goto :usage
if "%MODE%"=="/?" goto :usage

if "%MODE%"=="" set "MODE=debug"
if "%PLATFORM%"=="" set "PLATFORM=windows"

:: Validate scons
where scons >nul 2>&1
if errorlevel 1 (
    echo ERROR: scons not found in PATH. Activate your Python virtual environment first.
    goto :fail
)

:: Validate emscripten for web builds
if "%PLATFORM%"=="web" (
    where emcc >nul 2>&1
    if errorlevel 1 (
        echo ERROR: emcc ^(Emscripten^) not found in PATH.
        echo   Install Emscripten 3.1+ and activate it: emsdk activate latest
        goto :fail
    )
)

:: Count CPU cores for parallel build
set "JOBS=%NUMBER_OF_PROCESSORS%"
if "%JOBS%"=="" set "JOBS=4"

echo === gdcpp build: mode=%MODE% platform=%PLATFORM% jobs=%JOBS% ===

if "%MODE%"=="debug" goto :build_debug
if "%MODE%"=="release" goto :build_release
echo ERROR: Unknown mode '%MODE%'. Use: debug or release
goto :fail

:build_debug
:: Auto-init godot-cpp submodule if needed
if not exist "godot-cpp\SConstruct" (
    echo --- Initializing godot-cpp submodule...
    git submodule update --init --recursive godot-cpp
    if errorlevel 1 goto :fail
)

:: Ensure .godot dir with extension_list.cfg for debug
call :setup_godot_dir
echo res://bin/gdcpp.gdextension> "project\.godot\extension_list.cfg"

echo --- Building GDExtension debug...
scons platform=%PLATFORM% target=template_debug -j%JOBS%
if errorlevel 1 goto :fail

:: Copy debug output
set "BUILD_DIR=build-%PLATFORM%\debug"
if not exist "%BUILD_DIR%" mkdir "%BUILD_DIR%"
copy /y "project\bin\libgdcpp*" "%BUILD_DIR%\" >nul 2>&1

echo --- Build complete. Output in %BUILD_DIR%\
goto :done

:build_release
:: Validate GODOT_SOURCE
if "%GODOT_SOURCE%"=="" goto :no_source
if not exist "%GODOT_SOURCE%\SConstruct" goto :bad_source
goto :source_ok

:no_source
echo ERROR: GODOT_SOURCE environment variable not set.
echo   Set it to the path of your Godot 4.5.1 source tree.
goto :fail

:bad_source
echo ERROR: GODOT_SOURCE does not contain a Godot source tree.
goto :fail

:source_ok
echo --- GODOT_SOURCE=%GODOT_SOURCE%

set "PROJECT_DIR=%cd%"
set "MODULE_PATH=%cd%\module"
set "PROFILE_PATH=%cd%\custom.py"

:: Web release needs extra flags
if "%PLATFORM%"=="web" goto :release_web
goto :release_native

:release_native
echo --- Building Godot with gdcpp module release...
pushd "%GODOT_SOURCE%"
scons platform=%PLATFORM% target=template_release profile="%PROFILE_PATH%" custom_modules="%MODULE_PATH%" -j%JOBS%
if errorlevel 1 popd & goto :fail
popd

:: Copy only the executables (not .exp/.lib linker artifacts)
set "BUILD_DIR=build-%PLATFORM%\release"
if not exist "%BUILD_DIR%" mkdir "%BUILD_DIR%"
if exist "%BUILD_DIR%\*.pck" del /q "%BUILD_DIR%\*.pck"

echo --- Copying output to %BUILD_DIR%\
copy /y "%GODOT_SOURCE%\bin\godot.windows.template_release*.exe" "%BUILD_DIR%\" >nul 2>&1

:: Embed project data into the executable
call :setup_godot_dir
echo --- Packing project data into executable...
python "%~dp0pack.py" "%PROJECT_DIR%\project" "%BUILD_DIR%\temp.pck" --embed "%BUILD_DIR%\godot.windows.template_release.x86_64.exe"
if errorlevel 1 goto :fail
:: Also embed into console variant
python "%~dp0pack.py" "%PROJECT_DIR%\project" "%BUILD_DIR%\temp.pck" --embed "%BUILD_DIR%\godot.windows.template_release.x86_64.console.exe"
if errorlevel 1 goto :fail
if exist "%BUILD_DIR%\*.pck" del /q "%BUILD_DIR%\*.pck"

echo --- Release build complete. Output in %BUILD_DIR%\
goto :done

:release_web
echo --- Building Godot for web with gdcpp module release...
pushd "%GODOT_SOURCE%"
scons platform=web target=template_release profile="%PROFILE_PATH%" custom_modules="%MODULE_PATH%" threads=no dlink_enabled=no -j%JOBS%
if errorlevel 1 popd & goto :fail
popd

set "BUILD_DIR=build-web\release"
if not exist "%BUILD_DIR%" mkdir "%BUILD_DIR%"

echo --- Copying web output to %BUILD_DIR%\
copy /y "%GODOT_SOURCE%\bin\godot.web.template_release*.wasm" "%BUILD_DIR%\" >nul 2>&1
copy /y "%GODOT_SOURCE%\bin\godot.web.template_release*.js" "%BUILD_DIR%\" >nul 2>&1

:: Verify at least the .wasm arrived
dir /b "%BUILD_DIR%\*.wasm" >nul 2>&1
if errorlevel 1 (
    echo ERROR: No .wasm file found after build. Check %GODOT_SOURCE%\bin\ for output.
    dir /b "%GODOT_SOURCE%\bin\godot.web*" 2>nul
    goto :fail
)

:: Determine the base name from the .wasm file that was copied
for %%f in ("%BUILD_DIR%\*.wasm") do set "WEB_BASE=%%~nf"

:: Create standalone .pck (cannot embed into wasm)
call :setup_godot_dir
echo --- Packing project data...
python "%~dp0pack.py" "%PROJECT_DIR%\project" "%BUILD_DIR%\%WEB_BASE%.pck"
if errorlevel 1 goto :fail

:: Generate HTML shell with correct filenames
echo --- Generating index.html for %WEB_BASE%...
python -c "import sys; t=open(sys.argv[1]).read(); t=t.replace('__GODOT_JS__',sys.argv[2]+'.js').replace('__GODOT_BASE__',sys.argv[2]); open(sys.argv[3],'w').write(t)" "%~dp0web_shell.html" "%WEB_BASE%" "%BUILD_DIR%\index.html"

echo --- Web release build complete. Output in %BUILD_DIR%\
goto :done

:setup_godot_dir
if not exist "project\.godot" mkdir "project\.godot"
if not exist "project\.godot\global_script_class_cache.cfg" (
    echo [^"^"]> "project\.godot\global_script_class_cache.cfg"
    echo.>> "project\.godot\global_script_class_cache.cfg"
    echo list=[]>> "project\.godot\global_script_class_cache.cfg"
)
exit /b 0

:usage
echo Usage: build.bat [debug^|release] [windows^|web]
echo.
echo Modes:
echo   debug    Build GDExtension shared library via godot-cpp (default)
echo   release  Build single binary via Godot module system (needs GODOT_SOURCE)
echo.
echo Platforms:
echo   windows  Windows native build (default)
echo   web      WebAssembly build via Emscripten (needs emcc in PATH)
echo.
echo Examples:
echo   build.bat                   Debug build for Windows
echo   build.bat release           Release build for Windows
echo   build.bat debug web         Debug GDExtension for web
echo   build.bat release web       Release build for web
exit /b 0

:done
echo.
echo === BUILD SUCCEEDED ===
pause
exit /b 0

:fail
echo.
echo === BUILD FAILED ===
pause
exit /b 1
