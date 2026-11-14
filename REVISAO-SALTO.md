# Revisao tecnica — 14/11/2026

## Escopo e evidencia

Revisados cliente C++, protocolo, servidor, REDscript, simulador ativo,
instalador, workflow e contrato Lua. Simuladores historicos consultados como
contexto; nao foram todos executados.

O log existente em %LOCALAPPDATA%/CPM/logs/CPMClient.log, registro de 14/11,
11:49:57-58, mostra detalhes 18 -> 14 -> 23. Rede Z sobe de 7.856 para 8.986;
Real Z permanece em 7.856 nas amostras antes e apos solicitar teleporte.
O salto chega pela rede, mas nao ha elevacao medida nessa execucao.
Teleporte pode ser diferido: amostra imediatamente apos a chamada, sozinha,
nao comprova rejeicao pelo motor.

O codigo recebido nao envia PhysicalImpulseEvent. Teleporta um NPC Animals com
controlador/collider ativo. Interferencia desse controlador e uma hipotese
forte para altura travada, ainda nao confirmada por teste comparativo no jogo.

Space alimenta a maquina de estados de PlayerPuppet. O remoto nasce como
Character.animals_bouncer2_melee2_fists_mb, um NPCPuppet. Enviar Jump nao executa
a maquina de locomocao de V nem adiciona clips ao grafo desse NPC.

## Alteracoes feitas

- Collider desativado durante a trajetoria aerea recebida e reativado na saida
  ou timeout. Movimento terrestre preserva o controlador normal.
- LocomotionStateMachine.inAirState aplicado e restaurado; InAir antes de Jump,
  seguindo a ordem encontrada nos scripts do jogador.
- Queda pode comecar sem salto anterior. Novo estado de salto durante o ar
  solicita outro evento, incluindo transicao de queda para segundo salto.
- Aterrissagem aguarda Z de rede estabilizar, inclusive em plataformas mais altas.
- Diagnostico distingue timeout e salto encerrado sem elevacao real medida.
- PlayerStateMachine.Weapon substituido por RightWeapon. O primeiro nao existe
  na base instalada e impedia compilar o projeto baixado. O script instalado
  no jogo era diferente: usava weaponState = 0.
- Cliente C++ descarta sequencias UDP antigas/duplicadas, como o servidor ja faz.
- Teste -AirOnly executa dois saltos perto do observador, sem caminhada longa.

## Validacao

REDscript compilado com scc.exe e Codeware da instalacao local, contra copia
de final.redscripts. Resultado: Compilation complete. Saida isolada no projeto;
log em validation/redscript-compile.log. Nenhum patch instalado no jogo.

Teste Python executou o PowerShell real contra receptor UDP isolado em porta
temporaria: PASS para 160 pacotes, payload v2 de 66 bytes, sequencias ordenadas,
dois arcos e estados 1 -> 18 -> 14 -> 23 -> 1.

C++ nao recompilado: MSVC/CMake nao encontrados nas buscas locais realizadas.
Nao houve novo teste visual no Cyberpunk. Compilacao nao prova animacao correta.

## Instalacao e teste visual

1. Feche o jogo e preserve o REDscript instalado.
2. Copie resources/r6/scripts/CPM/CPMClient.reds para
   D:/SteamLibrary/steamapps/common/Cyberpunk 2077/r6/scripts/CPM/CPMClient.reds.
3. Use a DLL 0.3.0.0 existente ou recompile o pacote. Nenhuma assinatura nativa
   ou layout de pacote mudou. Deixe o jogo recompilar o REDscript normalmente.
4. Execute Start-Visual-Test.ps1 -AirOnly com CPMServer.exe na raiz do pacote;
   carregue um save em area plana e livre. Confira redscript_rCURRENT.log.
5. Compare Real Z e Rede Z durante os dois saltos. Depois observe separadamente
   pose de salto, queda, aterrissagem e retorno ao idle.

Originais preservados em review-backup-2026-11-14/.

## Limites e proxima etapa

Patch experimental. Liberar collider remove colisao local durante o ar: o
remoto pode atravessar paredes. A rede dita a trajetoria; nao e salto fisico
local identico ao Space. O NPC continua com IA e pode ignorar features de V.

Se Real Z continuar travado, sera necessario controlar movimento/transform por
implementacao nativa verificada. Se Real Z variar e a pose nao, sera necessario
um template/animgraph TPP com clips compativeis de salto, queda e aterrissagem.
Trocar o record por um nome supostamente de PlayerPuppet nao garante isso.

Outros pontos encontrados:

- Amostragem a 20 Hz pode perder transicoes breves; salto nao tem contador de
  evento persistente como tiro/recarga/melee.
- Getters nativos leem snapshots separados. Um pacote pode trocar entre X/Y/Z
  e estado; preferir snapshot atomico por atualizacao.
- AIMoveTo recebe destino uma vez por mudanca de locomocao. Enquanto ha
  velocidade, InterpolateTransform retorna sem corrigir posicao/rumo; pode
  haver deriva horizontal. Requer revisao especifica do movimento terrestre.
- Timeout de 100 ticks e nominal: callback pode atrasar; nao mede cinco segundos.
- Melee teleporta perto do observador local; nao reproduz coordenadas reais.
- Lua e contrato sem runtime. Servidor ainda nao tem autoridade fisica,
  autenticacao nem validacao de movimento para RP publico.

## Fontes primarias consultadas

- [LocomotionAirEvents e JumpEvents](https://github.com/CDPR-Modding-Documentation/Cyberpunk-Scripts/blob/main/scripts/cyberpunk/player/psm/locomotionTransitions.script)
- [API AIComponent: EnableCollider/DisableCollider](https://github.com/CDPR-Modding-Documentation/Cyberpunk-Scripts/blob/main/scripts/core/components/aiComponent.script)
- [PlayerStateMachineDef.RightWeapon](https://github.com/CDPR-Modding-Documentation/Cyberpunk-Scripts/blob/main/scripts/core/blackboard/blackboardDefinitions.script)
