# CPM 0.0.6.4 — Continuous Path

Versão experimental que mantém a mesma instância do comando de IA e atualiza
seu destino sem reenviar o comando ao controlador a cada atualização.

## O que esta versão testa

- API nativa de consulta dos jogadores remotos
- criação segura de uma entidade dinâmica pelo Codeware
- modelo humano padrão para o primeiro jogador remoto
- recepção de posição e rotação a cada 50 ms
- criação de um único comando por estado Walk ou Sprint
- atualização do destino no mesmo comando aproximadamente a cada 500 ms
- previsão do destino para sustentar caminhada, corrida e curvas
- histerese de 500 ms entre os estados Walk e Sprint
- teleporte somente quando a dessincronização ultrapassa 10 metros
- navegação e colisão habilitadas durante o movimento
- remoção automática da entidade após a desconexão
- toda a rede, sessões, heartbeat e reconexão do CPM 0.0.4

Nesta etapa somente o primeiro jogador remoto é renderizado. O objetivo é
validar continuidade de caminhada, corrida, rotação, navegação e timeout.

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

Execute o workflow **Build CPM 0.0.6.4 Continuous Path** e baixe:

```text
CPM-Windows-0.0.6.4-Continuous-Path
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
   aproximadamente 3 metros à frente do seu personagem.
5. Volte ao PowerShell e pressione ENTER. O inicializador executará:

```powershell
powershell -ExecutionPolicy Bypass -File ".\tools\CPM-Continuous-Path-Test-0.0.6.4.ps1"
```

Um NPC deverá ficar parado, caminhar, correr e percorrer uma curva. Ao final, o
servidor removerá o jogador por timeout e o NPC desaparecerá em até 15 segundos.

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
