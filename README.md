# CPM 0.2.0.0 — Native Movement Diagnostics

Esta versão inicia a substituição do controlador visual provisório após os testes 0.1.0.5 e 0.1.0.6 comprovarem que os pacotes chegam, mas o NPC ignora parte dos eventos de animação.

## Mudanças estruturais

- Locomoção em movimento deixa de ser sobrescrita por teleporte a cada atualização.
- `AIMoveToCommand` passa a controlar caminhada, corrida, agachamento e retorno enquanto o erro de posição permanece seguro.
- Salto e queda usam `AITeleportCommand` com trajetória Z real.
- O collider do boneco remoto é desativado durante o teste para impedir que a física o prenda imediatamente ao chão.
- O controlador de IA recebe `ForceTickNextFrame` durante o movimento aéreo.
- Estados reais dos comandos de movimento e melee são consultados por `GetCommandState`.
- A DLL recebe relatórios do REDscript e grava no `CPMClient.log`:
  - entidade preparada;
  - comando aceito ou rejeitado;
  - estado do movimento;
  - salto, queda e aterrissagem;
  - guardar arma;
  - estado do comando melee.
- Corrigida a mensagem interna do cliente que ainda mostrava 0.1.0.5.

## Artifact

```text
CPM-Windows-0.2.0.0-Native-Movement-Diagnostics
```

## Teste

```powershell
powershell -ExecutionPolicy Bypass -File ".\Start-Visual-Test.ps1"
```

Depois:

```powershell
Get-Content "$env:LOCALAPPDATA\CPM\logs\CPMClient.log" -Tail 120
```

Esta é uma versão de mudança estrutural e diagnóstico. O teste dentro do jogo determinará quais comandos o grafo do NPC aceita e quais ações exigirão um arquivo de animação/workspot próprio.
