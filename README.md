# CPM 0.2.0.1 — Smooth Air + Forced Holster + Melee Range

Esta versão preserva a caminhada, corrida e retorno confirmados como funcionais no teste 0.2.0.0.

## Correções desta rodada

- Removida a fila de `AITeleportCommand` criada a cada quadro aéreo.
- Salto agora usa transformação contínua com collider desativado.
- Curva aérea reduzida para aproximadamente 0,75 s de subida e 0,75 s de queda.
- Subida desacelera perto do ápice e queda acelera até o chão.
- O retorno continua sendo controlado pela IA, sem teleporte constante.
- Se `AIUnequipCommand` não esvaziar `WeaponRight`, o item é removido diretamente do slot.
- Antes do melee, o NPC é colocado a 1,60 m do jogador e virado para ele.
- Duração do comando melee aumentada para 3 segundos.
- Diagnósticos registram remoção forçada da arma e reposicionamento de combate.

## Artifact

```text
CPM-Windows-0.2.0.1-Smooth-Air-Holster-Melee
```

## Execução

```powershell
powershell -ExecutionPolicy Bypass -File ".\Start-Visual-Test.ps1"
```

Depois envie:

```powershell
Get-Content "$env:LOCALAPPDATA\CPM\logs\CPMClient.log" -Tail 120
```
