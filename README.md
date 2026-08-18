# CPM 0.1.0.3 — Native Actions Hotfix

Atualização baseada no vídeo e nos logs da 0.1.0.2. Preserva a interpolação
e a locomoção aprovadas e substitui eventos visuais genéricos por comandos de
IA e chamadas reais da arma.

## O que esta versão testa

- protocolo v2 incompatível com servidores e simuladores antigos
- parado, caminhada, corrida, agachamento, salto, queda e aterrissagem
- arma equipada, categoria da arma, mira e direção da mira
- eventos numerados de tiro, recarga e ataque corpo a corpo
- cancelamento do AIMoveToCommand antes de salto e combate
- caminhada agachada usando stealth locomotion
- pistola Omaha real equipada no slot WeaponRight
- mira com AIAimAtTargetCommand apontada para o jogador local
- tiros únicos com AIShootCommand
- recarga com WeaponObject.StartReload e eventos replicados
- ataque com AIMeleeAttackCommand e fallback QuickMelee
- estados aéreos com LocomotionStateMachine, Landing e eventos replicados
- retorno automático para perto do jogador antes do teste de combate
- log nativo de todas as mudanças e contadores de ação
- leitura dos estados reais pelo PlayerStateMachine Blackboard
- API nativa de consulta dos jogadores remotos
- criação segura de uma entidade dinâmica pelo Codeware
- criação simultânea de vários jogadores remotos
- controlador visual independente por jogador
- recepção de posição e rotação a cada 50 ms
- interpolação exponencial da transformação visual a cada 50 ms
- comando auxiliar enviado somente na troca entre Walk e Sprint
- nenhuma previsão agressiva na trajetória circular
- histerese de 500 ms entre os estados Walk e Sprint
- recuperação direta somente acima de 15 metros
- posição independente da navegação e dos obstáculos da IA
- remoção automática da entidade após a desconexão
- toda a rede, sessões, heartbeat e reconexão do CPM 0.0.4

O teste incluído conecta um jogador simulado e percorre todas as fases em uma
execução. Os comandos de combate usam o jogador local como alvo; utilize um
save de teste e um local seguro.

## Requisitos

- Cyberpunk 2077 Steam 2.31
- RED4ext compatível
- redscript estável
- Codeware compatível instalado
- `%LOCALAPPDATA%\CPM\connection.json` apontando para `127.0.0.1:11777`

O Codeware não está incluído neste pacote. Instale-o na raiz do jogo antes de
instalar o CPM. Sem ele, o redscript informará que `DynamicEntitySystem` não
existe e o jogo não carregará o script.

## Compilação no GitHub

Execute o workflow **Build CPM 0.1.0.3 Native Actions Hotfix** e baixe:

```text
CPM-Windows-0.1.0.3-Native-Actions-Hotfix
```

## Instalação

Copie as pastas `red4ext` e `r6` do artefato para a raiz:

```text
D:\SteamLibrary\steamapps\common\Cyberpunk 2077
```

Aceite substituir `CPMClient.dll` e `CPMClient.reds`.

## Teste visual

1. Feche o jogo e qualquer servidor CPM antigo.
2. Execute na raiz do artefato:

```powershell
powershell -ExecutionPolicy Bypass -File ".\Start-Visual-Test.ps1"
```

3. Abra o Cyberpunk e carregue um save quando solicitado.
   Use um save de teste: o modelo desta fase é apenas um marcador visual e
   ainda conserva comportamentos nativos de NPC.
4. Permaneça em qualquer local seguro do mapa. O NPC será criado
   à frente do seu personagem.
5. Volte ao PowerShell e pressione ENTER. O inicializador executará:

```powershell
powershell -ExecutionPolicy Bypass -File ".\tools\CPM-Native-Actions-Test-0.1.0.3.ps1"
```

O NPC deverá ficar parado, caminhar, correr, agachar, saltar, mirar, disparar,
recarregar e atacar. Ao final, será removido pelo timeout.

As coordenadas enviadas pelo simulador são tratadas como deslocamento relativo.
No instante da conexão, o CPM captura a posição atual do jogador real e usa esse
ponto como âncora. Portanto, CET, teleporte e coordenadas fixas não são necessários.

## Diagnóstico

Log do cliente:

```powershell
Get-Content "$env:LOCALAPPDATA\CPM\logs\CPMClient.log" -Wait -Tail 60
```

Log do redscript:

```powershell
Get-Content "D:\SteamLibrary\steamapps\common\Cyberpunk 2077\r6\logs\redscript_rCURRENT.log" -Tail 100
```

Se ocorrer erro de script, envie as últimas linhas de `redscript.log`. Se o
jogo abrir mas o NPC não aparecer, envie também `CPMClient.log` e a saída do
servidor.
