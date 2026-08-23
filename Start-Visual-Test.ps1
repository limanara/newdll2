$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$server = Join-Path $root "CPMServer.exe"
$simulator = Join-Path $root "tools\CPM-Physical-Air-Test-0.3.0.0.ps1"

if (!(Test-Path $server)) { throw "CPMServer.exe nao encontrado em $root" }
if (!(Test-Path $simulator)) { throw "Teste visual nao encontrado em $simulator" }

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " CPM 0.4.0.0 - TPP AIR PROBE DEV" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$serverProcess = Start-Process -FilePath $server -WorkingDirectory $root -PassThru
Write-Host "Servidor iniciado. Abra o Cyberpunk e carregue um save de teste." -ForegroundColor Yellow
Write-Host "Pode permanecer em qualquer local seguro do mapa." -ForegroundColor Yellow
Write-Host "Uma entidade TPP de teste sera criada a sua frente." -ForegroundColor Yellow
Write-Host "Este probe valida principalmente a classe TPP e o arco salto/queda/aterrissagem." -ForegroundColor Yellow
Read-Host "Quando estiver dentro do jogo, pressione ENTER"

& powershell -ExecutionPolicy Bypass -File $simulator

Write-Host ""
Write-Host "Teste visual concluido. O servidor continua aberto." -ForegroundColor Green
Write-Host "Confirme no log: PlayerPuppet true, NPCPuppet false, e as fases do arco aereo." -ForegroundColor Green

$log = Join-Path $env:LOCALAPPDATA "CPM\logs\CPMClient.log"
if (Test-Path $log) {
    Write-Host "Ultimas linhas do CPMClient.log:" -ForegroundColor Cyan
    Get-Content $log -Tail 120
} else {
    Write-Host "Log nao encontrado em $log" -ForegroundColor Red
}
