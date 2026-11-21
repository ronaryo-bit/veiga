@echo off
chcp 65001 >nul
if "%~1"=="" (
  echo Arraste o APK original sobre este arquivo .BAT.
  echo Nenhum arquivo sera enviado a internet.
  pause
  exit /b 1
)
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0analisar-apk.ps1" -ApkPath "%~1"
echo.
pause
