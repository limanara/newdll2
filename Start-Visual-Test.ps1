$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$server = Join-Path $root "CPMServer.exe"
$simulator = Join-Path $root "tools\CPM-Continuous-Path-Test-0.0.6.4.ps1"

if (!(Test-Path $server)) { throw "CPMServer.exe nao encontrado em $root" }
if (!(Test-Path $simulator)) { throw "Teste visual nao encontrado em $simulator" }

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " CPM 0.0.6.4 - CONTINUOUS PATH" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$serverProcess = Start-Process -FilePath $server -WorkingDirectory $root -PassThru
Write-Host "Servidor iniciado. Abra o Cyberpunk e carregue um save de teste." -ForegroundColor Yellow
Write-Host "Pode permanecer em qualquer local seguro do mapa." -ForegroundColor Yellow
Write-Host "O NPC sera criado aproximadamente 3 metros a sua frente." -ForegroundColor Yellow
Write-Host "O teste cobre parado, caminhada, corrida, curva e timeout." -ForegroundColor Yellow
Read-Host "Quando estiver dentro do jogo, pressione ENTER"

& powershell -ExecutionPolicy Bypass -File $simulator

Write-Host ""
Write-Host "Teste visual concluido. O servidor continua aberto." -ForegroundColor Green
Write-Host "A entidade remota deve andar em circulo e desaparecer depois do timeout." -ForegroundColor Green

$log = Join-Path $env:LOCALAPPDATA "CPM\logs\CPMClient.log"
if (Test-Path $log) {
    Write-Host "Ultimas linhas do CPMClient.log:" -ForegroundColor Cyan
    Get-Content $log -Tail 40
} else {
    Write-Host "Log nao encontrado em $log" -ForegroundColor Red
}
