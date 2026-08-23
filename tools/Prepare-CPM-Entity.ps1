param(
    [Parameter(Mandatory = $true)]
    [string]$SourceEnt
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$target = Join-Path $root "wolvenkit\source\archive\cpm\entities\cpm_remote_player.ent"

if (!(Test-Path -LiteralPath $SourceEnt -PathType Leaf)) {
    throw "Template .ent nao encontrado: $SourceEnt"
}
if ([IO.Path]::GetExtension($SourceEnt) -ne ".ent") {
    throw "O arquivo precisa possuir extensao .ent."
}

New-Item -ItemType Directory -Force -Path (Split-Path -Parent $target) | Out-Null
Copy-Item -LiteralPath $SourceEnt -Destination $target -Force

$size = (Get-Item -LiteralPath $target).Length
if ($size -lt 1024) {
    Remove-Item -LiteralPath $target -Force
    throw "O .ent parece invalido: tamanho inferior a 1 KB."
}

Write-Host "Template preparado:" -ForegroundColor Green
Write-Host $target
Write-Host "Tamanho: $size bytes"
Write-Host "Agora o recurso deve ser editado e empacotado pelo WolvenKit."
