# CPM 0.3.0.0 — Physical Air Driver + Diagnostics

A versão 0.2.0.2 permanece como base aprovada para locomoção terrestre, arma, recarga, holster e melee.

## Mudança estrutural

- O collider do puppet remoto permanece ativo.
- O início do salto envia um `PhysicalImpulseEvent` vertical apenas uma vez.
- Nenhum teleporte é executado durante a fase aérea.
- A gravidade e o character controller do jogo passam a controlar a trajetória.
- A posição Z real da entidade é medida durante todo o salto.
- A aterrissagem só finaliza quando há proximidade com o Z inicial ou timeout de segurança.
- Logs comparam Z recebido da rede, Z real, início, pico e altura atingida.

## Artifact

`CPM-Windows-0.3.0.0-Physical-Air-Driver-Diagnostics`

## Execução

```powershell
powershell -ExecutionPolicy Bypass -File ".\Start-Visual-Test.ps1"
```

Esta é uma versão experimental do novo controlador aéreo. Se o puppet ignorar o impulso, o log demonstrará isso objetivamente e a próxima etapa será substituir o archetype NPC por uma entidade TPP com move component próprio.
