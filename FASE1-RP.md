# CPM RP — Fase 1 (protótipo)

## Alterações aplicadas

- REDscript: NPC remoto agora usa coordenadas globais X/Y/Z recebidas da rede, sem reposicionamento artificial na frente do jogador local.
- Servidor: streaming de estados por proximidade (raio 180 metros), com `PlayerLeft` ao sair do alcance.
- Entrada no alcance: envio do estado atual do jogador já presente ao novo observador.
- Pacotes: descarta posições/rotações não finitas e sequências antigas ou duplicadas.
- Mantém protocolo v2, UDP 11777 e compatibilidade com os pacotes originais.

## Importante

O servidor continua sendo um protótipo **sem autenticação**, criptografia ou validação de velocidade. Não exponha na internet como servidor público de RP. Não foi possível executar Cyberpunk 2077 nem compilar o cliente Windows neste ambiente. O comportamento visual, incluindo spawn de NPCs em posições distantes, ainda precisa ser validado dentro do jogo.

## Lua

`rp_resources/core/` é um **rascunho do contrato** de resource e API. **Lua ainda não está integrado ao binário C++** e os scripts não serão executados. A próxima etapa é incorporar o runtime Lua ao servidor, criar `RegisterCommand`, `AddEventHandler`, `TriggerEvent` e um carregador de resources isolado, além de conectar eventos reais de sessão.

## Compilação no Windows

Use `build-windows.bat` na raiz do projeto (CMake, MSVC e dependências RED4ext/RedLib). Instale o cliente e os REDscripts conforme `install-client.bat`. Inicie o `CPMServer.exe` e conecte duas instâncias compatíveis do jogo. Para teste de streaming, aproxime e afaste os jogadores por mais de 180 metros, observando spawn/despawn e logs.

## Critérios de aceite

1. Dois clientes conectam e recebem IDs diferentes.
2. O remoto surge em coordenadas reais quando ambos estão próximos.
3. O remoto desaparece ao ultrapassar 180 metros.
4. Reaparece quando retorna ao alcance.
5. Posições NaN/Inf e sequências repetidas não são retransmitidas.
6. Reconexão e saltos não provocam crash.

Os itens acima são **testes pendentes**, não resultados já confirmados.
