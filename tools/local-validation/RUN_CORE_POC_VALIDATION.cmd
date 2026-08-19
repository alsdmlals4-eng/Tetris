@echo off
setlocal EnableExtensions DisableDelayedExpansion

set "GODOT_VERSION=4.7.1"
set "GUT_VERSION=9.7.1"
set "CACHE_ROOT=%LOCALAPPDATA%\TetrisCorePocValidation"
set "GODOT_DIR=%CACHE_ROOT%\godot-%GODOT_VERSION%"
set "GODOT_ZIP=%CACHE_ROOT%\Godot_v%GODOT_VERSION%-stable_win64.exe.zip"
set "GODOT_EXE=%GODOT_DIR%\Godot_v%GODOT_VERSION%-stable_win64.exe"
set "GUT_ZIP=%CACHE_ROOT%\Gut-%GUT_VERSION%.zip"
set "GUT_EXTRACT=%CACHE_ROOT%\Gut-%GUT_VERSION%"
set "PREFLIGHT_PATH=%USERPROFILE%\Desktop\Tetris_Core_POC_Preflight.txt"
set "REPORT_PATH=%USERPROFILE%\Desktop\Tetris_Core_POC_Validation.json"
set "IMPORT_LOG=%CACHE_ROOT%\import.log"
set "GUT_LOG=%CACHE_ROOT%\gut.log"
set "GUT_INSTALLED_BY_LAUNCHER=0"
set "POC_COMMIT=UNKNOWN"

for %%I in ("%~dp0..\..") do set "REPO_ROOT=%%~fI"

echo ============================================================
echo   Tetris Core POC - Windows Local Validation
echo ============================================================
echo.
echo Repository:
echo   %REPO_ROOT%
echo.
echo Evidence will be written to:
echo   %PREFLIGHT_PATH%
echo   %REPORT_PATH%
echo.

if not exist "%REPO_ROOT%\project.godot" (
  echo [BLOCKED] project.godot was not found.
  goto :blocked
)

where curl.exe >nul 2>&1
if errorlevel 1 (
  echo [BLOCKED] curl.exe was not found on this Windows installation.
  goto :blocked
)

where tar.exe >nul 2>&1
if errorlevel 1 (
  echo [BLOCKED] tar.exe was not found on this Windows installation.
  goto :blocked
)

if not exist "%CACHE_ROOT%" mkdir "%CACHE_ROOT%" >nul 2>&1

if not exist "%GODOT_EXE%" (
  echo [1/6] Downloading portable Godot %GODOT_VERSION%...
  if exist "%GODOT_ZIP%" del /q "%GODOT_ZIP%" >nul 2>&1
  curl.exe -fL --retry 3 "https://github.com/godotengine/godot/releases/download/%GODOT_VERSION%-stable/Godot_v%GODOT_VERSION%-stable_win64.exe.zip" -o "%GODOT_ZIP%"
  if errorlevel 1 (
    echo [BLOCKED] Godot download failed.
    goto :blocked
  )
  if exist "%GODOT_DIR%" rmdir /s /q "%GODOT_DIR%" >nul 2>&1
  mkdir "%GODOT_DIR%" >nul 2>&1
  tar.exe -xf "%GODOT_ZIP%" -C "%GODOT_DIR%"
  if errorlevel 1 (
    echo [BLOCKED] Godot extraction failed.
    goto :blocked
  )
)

if not exist "%GODOT_EXE%" (
  echo [BLOCKED] Portable Godot executable was not found after extraction.
  goto :blocked
)

for /f "usebackq delims=" %%V in (`"%GODOT_EXE%" --version 2^>nul`) do if not defined LOCAL_GODOT_VERSION set "LOCAL_GODOT_VERSION=%%V"
if not defined LOCAL_GODOT_VERSION (
  echo [BLOCKED] Godot version could not be read.
  goto :blocked
)

echo %LOCAL_GODOT_VERSION% | findstr /b /c:"%GODOT_VERSION%.stable" >nul
if errorlevel 1 (
  echo [BLOCKED] Expected Godot %GODOT_VERSION%.stable but found %LOCAL_GODOT_VERSION%.
  goto :blocked
)

if not exist "%REPO_ROOT%\addons\gut\gut_cmdln.gd" (
  echo [2/6] Preparing GUT %GUT_VERSION% locally...
  if exist "%GUT_ZIP%" del /q "%GUT_ZIP%" >nul 2>&1
  if exist "%GUT_EXTRACT%" rmdir /s /q "%GUT_EXTRACT%" >nul 2>&1
  curl.exe -fL --retry 3 "https://github.com/bitwes/Gut/archive/refs/tags/v%GUT_VERSION%.zip" -o "%GUT_ZIP%"
  if errorlevel 1 (
    echo [BLOCKED] GUT download failed.
    goto :blocked
  )
  tar.exe -xf "%GUT_ZIP%" -C "%CACHE_ROOT%"
  if errorlevel 1 (
    echo [BLOCKED] GUT extraction failed.
    goto :blocked
  )
  if not exist "%GUT_EXTRACT%\addons\gut\gut_cmdln.gd" (
    echo [BLOCKED] GUT files were not found after extraction.
    goto :blocked
  )
  if not exist "%REPO_ROOT%\addons" mkdir "%REPO_ROOT%\addons" >nul 2>&1
  xcopy "%GUT_EXTRACT%\addons\gut" "%REPO_ROOT%\addons\gut\" /e /i /y >nul
  if errorlevel 1 (
    echo [BLOCKED] GUT could not be copied into the temporary project addon path.
    goto :blocked
  )
  set "GUT_INSTALLED_BY_LAUNCHER=1"
)

if not exist "%REPO_ROOT%\addons\gut\gut_cmdln.gd" (
  echo [BLOCKED] gut_cmdln.gd is unavailable.
  goto :blocked
)

where git.exe >nul 2>&1
if not errorlevel 1 (
  for /f "usebackq delims=" %%C in (`git -C "%REPO_ROOT%" rev-parse HEAD 2^>nul`) do if not defined FOUND_COMMIT set "FOUND_COMMIT=%%C"
  if defined FOUND_COMMIT set "POC_COMMIT=%FOUND_COMMIT%"
)

echo [3/6] Running local Godot import/parse...
"%GODOT_EXE%" --headless --path "%REPO_ROOT%" --editor --quit > "%IMPORT_LOG%" 2>&1
if errorlevel 1 goto :import_fail
findstr /c:"SCRIPT ERROR:" /c:"Parse Error" "%IMPORT_LOG%" >nul 2>&1
if not errorlevel 1 goto :import_fail

echo [4/6] Running the complete local GUT suite...
"%GODOT_EXE%" --headless --path "%REPO_ROOT%" -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit > "%GUT_LOG%" 2>&1
set "GUT_EXIT=%ERRORLEVEL%"
if not "%GUT_EXIT%"=="0" goto :gut_fail
findstr /c:"SCRIPT ERROR:" "%GUT_LOG%" >nul 2>&1
if not errorlevel 1 goto :gut_fail
findstr /c:"All tests passed!" "%GUT_LOG%" >nul 2>&1
if errorlevel 1 goto :gut_fail

(
  echo GODOT_VERSION=%LOCAL_GODOT_VERSION%
  echo GUT_VERSION=%GUT_VERSION%
  echo COMMIT=%POC_COMMIT%
  echo IMPORT_PARSE=PASS
  echo GUT_SUITE=PASS
) > "%PREFLIGHT_PATH%"

if exist "%REPORT_PATH%" del /q "%REPORT_PATH%" >nul 2>&1

echo [5/6] Local preflight PASS.
echo.
echo The interactive 45-second validation will start now.
echo Follow the NEXT instruction shown inside the game.
echo Keep the encounter open until the status says PASS and EVIDENCE SAVED.
echo.

set "POC_MANUAL_VALIDATION=1"
set "POC_VALIDATION_REPORT_PATH=%REPORT_PATH%"
set "POC_VALIDATION_GUT_VERSION=%GUT_VERSION%"
set "POC_VALIDATION_COMMIT=%POC_COMMIT%"

start "" /wait "%GODOT_EXE%" --path "%REPO_ROOT%"

echo [6/6] Checking human-play evidence...
if not exist "%REPORT_PATH%" goto :manual_incomplete
findstr /c:"PASS" "%REPORT_PATH%" >nul 2>&1
if errorlevel 1 goto :manual_incomplete

echo.
echo ============================================================
echo   VALIDATION_PASS
echo ============================================================
echo Local Godot/GUT preflight: PASS
echo Human-operated 45-second contract: PASS
echo.
echo Evidence:
echo   %PREFLIGHT_PATH%
echo   %REPORT_PATH%
echo.
explorer.exe /select,"%REPORT_PATH%" >nul 2>&1
goto :cleanup_success

:import_fail
(
  echo GODOT_VERSION=%LOCAL_GODOT_VERSION%
  echo GUT_VERSION=%GUT_VERSION%
  echo COMMIT=%POC_COMMIT%
  echo IMPORT_PARSE=FAIL
  echo GUT_SUITE=NOT_RUN
) > "%PREFLIGHT_PATH%"
echo [BLOCKED] Local Godot import/parse failed.
echo Log: %IMPORT_LOG%
goto :blocked

:gut_fail
(
  echo GODOT_VERSION=%LOCAL_GODOT_VERSION%
  echo GUT_VERSION=%GUT_VERSION%
  echo COMMIT=%POC_COMMIT%
  echo IMPORT_PARSE=PASS
  echo GUT_SUITE=FAIL
) > "%PREFLIGHT_PATH%"
echo [BLOCKED] Local GUT suite failed or produced an unexpected script error.
echo Log: %GUT_LOG%
goto :blocked

:manual_incomplete
echo.
echo ============================================================
echo   VALIDATION_NOT_COMPLETE
echo ============================================================
echo Local Godot/GUT preflight: PASS
echo Human-operated 45-second contract: NOT_COMPLETE
echo.
echo Re-run this file and follow every NEXT instruction until
echo the game shows PASS and EVIDENCE SAVED before closing it.
echo.
goto :cleanup_failure

:blocked
echo.
echo Preflight evidence, when available:
echo   %PREFLIGHT_PATH%
echo.
goto :cleanup_failure

:cleanup_success
if "%GUT_INSTALLED_BY_LAUNCHER%"=="1" rmdir /s /q "%REPO_ROOT%\addons\gut" >nul 2>&1
echo Press any key to close this window.
pause >nul
exit /b 0

:cleanup_failure
if "%GUT_INSTALLED_BY_LAUNCHER%"=="1" rmdir /s /q "%REPO_ROOT%\addons\gut" >nul 2>&1
echo Press any key to close this window.
pause >nul
exit /b 1
