@echo off
setlocal
set "GAME=%~1"
if "%GAME%"=="" set "GAME=C:\Program Files (x86)\Steam\steamapps\common\Cyberpunk 2077"
if not exist "%GAME%\bin\x64\Cyberpunk2077.exe" (echo Pasta do jogo invalida.& pause & exit /b 1)
if not exist "build\Release\CPMClient.dll" (echo Compile primeiro com build-windows.bat.& pause & exit /b 1)
mkdir "%GAME%\red4ext\plugins\CPMClient" 2>nul
mkdir "%GAME%\r6\scripts\CPM" 2>nul
copy /Y "build\Release\CPMClient.dll" "%GAME%\red4ext\plugins\CPMClient\CPMClient.dll"
copy /Y "resources\r6\scripts\CPM\CPMClient.reds" "%GAME%\r6\scripts\CPM\CPMClient.reds"
echo CPM Client 0.0.6.1 Smooth Sync Hotfix instalado.
pause
