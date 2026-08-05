$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$server = Join-Path $root "CPMServer.exe"
$simulator = Join-Path $root "tools\CPM-10-Players-Big-Test-0.0.4.ps1"
if (!(Test-Path $server)) { throw "CPMServer.exe não encontrado em $root" }
if (!(Test-Path $simulator)) { throw "Simulador não encontrado em $simulator" }

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "       CPM 0.0.4 BIG TEST" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
$process = Start-Process -FilePath $server -WorkingDirectory $root -PassThru
Write-Host "Servidor iniciado. Abra o Cyberpunk e carregue seu save." -ForegroundColor Yellow
Read-Host "Quando estiver dentro do jogo, pressione ENTER para iniciar 10 simuladores"
& powershell -ExecutionPolicy Bypass -File $simulator
Write-Host ""
Write-Host "Teste concluído. Verificando as últimas linhas do CPMClient.log..." -ForegroundColor Cyan
$log = Join-Path $env:LOCALAPPDATA "CPM\logs\CPMClient.log"
if (Test-Path $log) { Get-Content $log -Tail 35 } else { Write-Host "Log do cliente não encontrado: $log" -ForegroundColor Red }
Write-Host "O servidor continuará aberto para inspeção. Encerre-o com CTRL+C na janela dele."
