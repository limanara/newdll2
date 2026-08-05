@echo off
setlocal
where cmake >nul 2>nul || (echo CMake nao encontrado. Instale Visual Studio 2022 com CMake.& pause & exit /b 1)
cmake -S . -B build -A x64
if errorlevel 1 exit /b 1
cmake --build build --config Release
if errorlevel 1 exit /b 1
echo CPMClient.dll e CPMServer.exe criados em build\Release
pause
