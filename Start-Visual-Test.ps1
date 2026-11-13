$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$server = Join-Path $root "CPMServer.exe"
$simulator = Join-Path $root "tools\CPM-Physical-Air-Test-0.3.0.0.ps1"

if (!(Test-Path $server)) { throw "CPMServer.exe nao encontrado em $root" }
if (!(Test-Path $simulator)) { throw "Teste visual nao encontrado em $simulator" }

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " CPM 0.3.0.0 - PHYSICAL AIR DRIVER + DIAGNOSTICS" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Evita abrir um segundo servidor quando a porta ja esta em uso.
$existing = Get-NetUDPEndpoint -LocalPort 11777 -ErrorAction SilentlyContinue
if (!$existing) {
    $serverProcess = Start-Process -FilePath $server -WorkingDirectory $root -PassThru
    Start-Sleep -Seconds 2
} else {
    Write-Host "Servidor UDP 11777 ja esta ativo; reutilizando." -ForegroundColor Green
}
Write-Host "Servidor iniciado. Abra o Cyberpunk e carregue um save de teste." -ForegroundColor Yellow
Write-Host "Pode permanecer em qualquer local seguro do mapa." -ForegroundColor Yellow
Write-Host "O simulador consultara sua posicao automaticamente no servidor." -ForegroundColor Yellow
Write-Host "O teste cobre locomocao, salto, agachamento, mira, tiro, recarga e melee." -ForegroundColor Yellow
Read-Host "Quando estiver dentro do jogo, pressione ENTER"

& powershell -ExecutionPolicy Bypass -File $simulator

Write-Host ""
Write-Host "Teste visual concluido. O servidor continua aberto." -ForegroundColor Green
Write-Host "A entidade deve executar todas as fases e desaparecer depois do timeout." -ForegroundColor Green

$log = Join-Path $env:LOCALAPPDATA "CPM\logs\CPMClient.log"
if (Test-Path $log) {
    Write-Host "Ultimas linhas do CPMClient.log:" -ForegroundColor Cyan
    Get-Content $log -Tail 120
} else {
    Write-Host "Log nao encontrado em $log" -ForegroundColor Red
}
