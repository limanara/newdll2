# CPM 0.2.0.2 — Air Locomotion + Verified Holster + Melee Puppet

Esta versão corrige os dois bloqueios comprovados pelos logs do teste 0.2.0.1.

## Correções

- A fase aérea não cancela mais o controlador de locomocao do NPC.
- Salto e queda mantêm uma animação-base ativa enquanto o eixo Z é sincronizado.
- A remoção de arma possui temporizador próprio e não depende mais do evento melee.
- O slot `WeaponRight` é verificado depois da remoção; o log registra estado 5 para sucesso e 6 para falha.
- O melee também força o esvaziamento do slot antes de enviar o ataque.
- O puppet remoto agora usa um archetype com suporte nativo a combate desarmado.
- O retorno continua usando movimento de IA, preservando a corrida já confirmada.
- O log final foi ampliado para 120 linhas.

## Limite conhecido

O salto ainda é uma aproximação de sincronização de NPC. A animação autêntica de jogador remoto exigirá um driver/workspot próprio com recursos de animação do jogo. Este teste verifica se o congelamento foi eliminado e se a trajetória, o holster e o melee avançaram.

## Artifact

```text
CPM-Windows-0.2.0.2-Air-Locomotion-Holster-Melee-Puppet
```

## Execução

```powershell
powershell -ExecutionPolicy Bypass -File ".\Start-Visual-Test.ps1"
```
