@echo off
setlocal

set "VALIDATION_SCRIPT=%~dp0tools\windows\run_local_validation.ps1"

if not exist "%VALIDATION_SCRIPT%" (
  echo [ERROR] Validation script was not found:
  echo %VALIDATION_SCRIPT%
  pause
  exit /b 2
)

if /I "%~1"=="--ci" (
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%VALIDATION_SCRIPT%" -Ci
  exit /b %ERRORLEVEL%
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%VALIDATION_SCRIPT%"
set "VALIDATION_EXIT=%ERRORLEVEL%"

echo.
if "%VALIDATION_EXIT%"=="0" (
  echo ============================================================
  echo   LOCAL VALIDATION PASS
  echo ============================================================
  echo Evidence is under:
  echo   %LOCALAPPDATA%\TetrisCorePocValidation
) else (
  echo ============================================================
  echo   LOCAL VALIDATION NOT COMPLETE / FAILED
  echo ============================================================
  echo Review the error above. Existing Godot installs and projects were not modified.
)

echo.
pause
exit /b %VALIDATION_EXIT%
