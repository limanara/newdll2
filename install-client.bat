@echo off
setlocal
set "GAME=%~1"
if "%GAME%"=="" set "GAME=C:\Program Files (x86)\Steam\steamapps\common\Cyberpunk 2077"
if not exist "%GAME%\bin\x64\Cyberpunk2077.exe" (echo Pasta do jogo invalida.& pause & exit /b 1)
set "DLL=red4ext\plugins\CPMClient\CPMClient.dll"
set "REDS=r6\scripts\CPM\CPMClient.reds"
if not exist "%DLL%" set "DLL=build\Release\CPMClient.dll"
if not exist "%REDS%" set "REDS=resources\r6\scripts\CPM\CPMClient.reds"
if not exist "%DLL%" (echo CPMClient.dll nao encontrada.& pause & exit /b 1)
if not exist "%REDS%" (echo CPMClient.reds nao encontrado.& pause & exit /b 1)
mkdir "%GAME%\red4ext\plugins\CPMClient" 2>nul
mkdir "%GAME%\r6\scripts\CPM" 2>nul
copy /Y "%DLL%" "%GAME%\red4ext\plugins\CPMClient\CPMClient.dll"
copy /Y "%REDS%" "%GAME%\r6\scripts\CPM\CPMClient.reds"
if not exist "%LOCALAPPDATA%\CPM" mkdir "%LOCALAPPDATA%\CPM"
if exist "connection.example.json" copy /Y "connection.example.json" "%LOCALAPPDATA%\CPM\connection.json"
echo CPM Client 0.1.0 Estados e Combate instalado.
pause
