@echo off
cd /d "%~dp0"
set GODOT=C:\Godot\Godot_v4.7.2-stable_win64.exe
if not exist "%GODOT%" (
  echo Godot was not found: %GODOT%
  echo Edit the GODOT line in this file to point to your Godot exe.
  pause
  exit /b 1
)
start "" "%GODOT%" --path .
