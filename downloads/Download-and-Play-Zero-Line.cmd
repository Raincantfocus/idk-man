@echo off
setlocal
set "ZERO_LINE_DEST=%~dp0Zero-Line-Playtest"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; $script=Join-Path $env:TEMP 'Get-Zero-Line.ps1'; Invoke-WebRequest -UseBasicParsing -Uri 'https://raw.githubusercontent.com/Raincantfocus/idk-man/zero-line-prototype/downloads/Get-Zero-Line.ps1' -OutFile $script; & $script -Destination $env:ZERO_LINE_DEST -Launch"
if errorlevel 1 pause
endlocal
