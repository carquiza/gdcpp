@echo off
setlocal

cd /d "%~dp0.."

set "TARGET=%~1"
if "%TARGET%"=="" set "TARGET=all"

if "%TARGET%"=="debug" goto :clean_debug
if "%TARGET%"=="release" goto :clean_release
if "%TARGET%"=="all" goto :clean_all
echo ERROR: Unknown target '%TARGET%'. Use: all, debug, or release
goto :fail

:clean_all
call :clean_debug
call :clean_release
goto :success

:clean_debug
echo --- Cleaning debug build artifacts...
del /q project\bin\libgdcpp* 2>nul
del /q .sconsign.dblite 2>nul
del /q gdcpp\src\*.obj 2>nul
del /q gdcpp\*.obj 2>nul
echo   Done.
goto :eof

:clean_release
echo --- Cleaning release build artifacts...
if exist build-windows rd /s /q build-windows
if exist build-linux rd /s /q build-linux
if exist build-web rd /s /q build-web
mkdir build-windows 2>nul
mkdir build-linux 2>nul
mkdir build-web 2>nul
echo   Done.
goto :eof

:success
echo.
echo === CLEAN DONE ===
pause
exit /b 0

:fail
pause
exit /b 1
