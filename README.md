# CPM 0.1.0.6 — Real Z + NPC Air + Return + Melee

Versão de correção baseada no teste visual da 0.1.0.5.

## Correções principais

- SALTO e QUEDA agora recebem uma trajetória Z real pela rede, em vez de manter Z=0 e depender somente de um offset local.
- O visual aplica a altura de rede diretamente durante a fase aérea.
- Foram removidos `AnimFeature_PlayerMovement` e `AnimFeature_PlayerLocomotionStateMachine`, que são específicos do player e podem ser ignorados por `NPCPuppet`.
- O NPC recebe recursos/eventos genéricos de movimento, salto, queda e aterrissagem.
- RETORNO agora envia corrida progressiva de X=29 até X=4; não existe mais teleporte proposital entre retorno e combate.
- O melee interrompe a locomoção durante toda a preparação, repete o unequip se necessário e aguarda até 1 segundo pela arma.
- O teste foi reorganizado para garantir que guardar arma, melee e estado final sejam enviados antes da desconexão.
- Versões do cliente, servidor, instalador, workflow e artifact foram sincronizadas em 0.1.0.6.

## Artifact

No GitHub Actions baixe:

```text
CPM-Windows-0.1.0.6-Real-Z-NPC-Air-Return-Melee
```

## Instalação

Copie as pastas `red4ext` e `r6` para a raiz do Cyberpunk 2077, aceitando substituir os arquivos anteriores.

## Teste

Na pasta extraída do artifact:

```powershell
powershell -ExecutionPolicy Bypass -File ".\Start-Visual-Test.ps1"
```

Depois do teste:

```powershell
Get-Content "$env:LOCALAPPDATA\CPM\logs\CPMClient.log" -Tail 80
```

O teste dentro do jogo continua obrigatório: o build valida C++ e empacotamento, mas o grafo de animação do NPC só pode ser confirmado em execução no Cyberpunk.
