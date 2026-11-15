# CPM — revisão pontual do salto (experimental)

## Alterações
- Evita disparar `Fall` por oscilação do Z interpolado enquanto a rede ainda indica `Jump` (detail 18).
- Mantém a transição de queda exclusivamente no estado de rede 14, tratado por `UpdateAirState`.
- Solicita `Idle` ao terminar o ciclo aéreo, além de limpar a feature `inAirState` e reativar o collider.
- `Start-Visual-Test.ps1` informa claramente se o modo `-AirOnly` foi selecionado.

## Limitação
O movimento vertical ainda usa `Teleport()` em `NPCPuppet`. Os logs anteriores mostram que o Z real não acompanha o Z recebido. **Esta revisão não demonstra que o salto físico foi resolvido**. `Idle` pode não ser reconhecido pelo animgraph Animals. Não foi possível compilar/validar REDscript no ambiente de execução atual nem testar no jogo.

## Instalação
1. Faça backup de `r6/scripts/CPM/CPMClient.reds`.
2. Atualize o repositório com este pacote e execute o workflow GitHub Actions para gerar uma distribuição consistente.
3. Instale o REDscript e DLL do build; atualize também `Start-Visual-Test.ps1` e `tools/CPM-Physical-Air-Test-0.3.0.0.ps1` na pasta do servidor.
4. Reinicie o jogo e o servidor. Execute `powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\\Start-Visual-Test.ps1 -AirOnly`.
5. Envie `%LOCALAPPDATA%/CPM/logs/CPMClient.log` e o `redscript_rCURRENT.log` se houver falha de compilação.

## Próximo diagnóstico se Real Z continuar fixo
Precisamos testar uma implementação nativa de transformação que não seja reancorada pelo controlador do NPC, ou mudar o tipo/controlador da entidade. A existência de `DisableCollider()` não prova que o teleporte respeite Z. A animação TPP requer validação separada.
