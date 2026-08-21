@echo off
setlocal

set "TETRIS_LAUNCHER=%~dp0tools\windows\start_tetris_local_executor.ps1"
if not exist "%TETRIS_LAUNCHER%" (
  echo [Tetris bootstrap] launcher not found: %TETRIS_LAUNCHER%
  pause
  exit /b 2
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%TETRIS_LAUNCHER%" %*
set "TETRIS_EXIT=%ERRORLEVEL%"
if not "%TETRIS_EXIT%"=="0" pause
exit /b %TETRIS_EXIT%
