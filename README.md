# CPM 0.1.0.5 — Native Air + Equip + Melee

Esta versão continua a 0.1.0.3/0.1.0.4 e foca somente nas fases que ainda falharam no teste visual.

## Alterações principais

- SALTO: mantém o controlador vertical visual e agora também aplica `AnimFeature_PlayerMovement` com velocidade vertical positiva e estado `inAirState=true`.
- QUEDA: aplica velocidade vertical negativa e mantém o estado aéreo até o pouso.
- ATERRISSAGEM: aplica `AnimFeature_Landing`, zera a velocidade vertical e força a postura em pé.
- RETORNO EM PÉ: não executa mais corrida de retorno. O NPC apenas sai do agachamento e permanece parado/em pé.
- EQUIPANDO ARMA: garante que a Omaha exista no inventário do NPC antes de enviar `AIEquipCommand`.
- GUARDANDO ARMA: agora usa `AIUnequipCommand` real no slot `WeaponRight`.
- MELEE: força postura em pé, cancela mira/tiro/recarga, solicita o unequip e aguarda 12 ticks (~600 ms) antes do `AIMeleeAttackCommand`.
- O evento melee também reforça `QuickMelee`, `MeleeAttack` e `Attack`.

## Build

No GitHub Actions execute o workflow:

```text
Build CPM 0.1.0.5 Native Air + Equip + Melee Controller
```

Baixe o artifact:

```text
CPM-Windows-0.1.0.5-Native-Air-Equip-Melee
```

## Instalação

Copie `red4ext` e `r6` do artifact para a raiz do Cyberpunk 2077 e aceite substituir os arquivos antigos.

## Teste

Na raiz do artifact:

```powershell
powershell -ExecutionPolicy Bypass -File ".\Start-Visual-Test.ps1"
```

O inicializador executa automaticamente:

```powershell
powershell -ExecutionPolicy Bypass -File ".\tools\CPM-Air-Melee-Test-0.1.0.5.ps1"
```

Fases de interesse:

```text
PARADO ANTES DO SALTO
SALTO
QUEDA
ATERRISSAGEM
RETORNO EM PE
EQUIPANDO ARMA
GUARDANDO ARMA
ATAQUE CORPO A CORPO
```

Depois do teste, envie as últimas linhas do log:

```powershell
Get-Content "$env:LOCALAPPDATA\CPM\logs\CPMClient.log" -Tail 60
```
