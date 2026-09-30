@echo off
rem Links the mod folder from this repo into the game mods folder (junction, no admin rights).
rem Usage: dev-link.cmd [path\to\mods]
setlocal
set "MODS=G:\SteamLibrary\steamapps\common\Warhammer 40,000 DARKTIDE\mods"
if not "%~1"=="" set "MODS=%~1"
set "TARGET=%MODS%\auspex_vitals"
if not exist "%MODS%\dmf" (
  echo Not a Darktide mods folder with DMF: "%MODS%"
  exit /b 2
)
if exist "%TARGET%" (
  echo Already exists: "%TARGET%" - remove it first to relink.
  exit /b 1
)
mklink /J "%TARGET%" "%~dp0auspex_vitals"
