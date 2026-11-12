@echo off
cd /d "%~dp0"
if not exist "files\patcher.ps1" (
  echo.
  echo [ERROR] Please extract the ZIP file first, then run UnkoTechnicaMod.bat from the extracted folder.
  echo [エラー] ZIPファイルを展開（すべて展開）してから、展開したフォルダの UnkoTechnicaMod.bat を実行してください。
  echo.
  pause
  exit /b 1
)
start "" powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%~dp0files\patcher.ps1"
