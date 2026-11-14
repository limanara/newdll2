# CPM — prototipo multiplayer para Cyberpunk 2077

Cliente RED4ext + REDscript/Codeware e servidor UDP C++ (protocolo v2).
O remoto e um NPCPuppet, nao um PlayerPuppet. Lua ainda nao esta integrado.

## Revisao do salto — 14/11/2026

O codigo recebido usava teleporte, apesar do nome Physical Air Driver.
O patch libera temporariamente o collider e aplica o parametro de animacao
aerea usado pelo jogador. Veja REVISAO-SALTO.md para diagnostico e limites.

Status: REDscript compilado; simulador validado com UDP isolado. Movimento e
animacao ainda precisam de teste no jogo. O grafo do NPC Animals pode nao
conter a animacao de salto de V. Nao ha garantia de reproduzir Space so com scripts.

Teste curto (CPMServer.exe precisa estar na raiz do pacote):

```powershell
powershell -ExecutionPolicy Bypass -File .\Start-Visual-Test.ps1 -AirOnly
```

Dois saltos parados a 3 metros. Sem -AirOnly, executa o teste completo.

Verificacao do simulador sem jogo:

```powershell
python tools/test_air_simulator.py
```

Compilacao C++: build-windows.bat com MSVC/CMake ou workflow GitHub Actions.
O REDscript corrigido funciona com as assinaturas nativas da DLL 0.3.0.0.
Recompile a DLL para incluir tambem o descarte de pacotes fora de ordem.
