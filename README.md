# CPM 0.0.8 — Multi Remote

Evolução da base estável 0.0.7. A interpolação fluida validada foi preservada,
mas agora cada jogador remoto recebe sua própria entidade e estado visual.

## O que esta versão testa

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

O teste incluído conecta cinco jogadores simulados ao mesmo tempo. Eles devem
aparecer em formação, permanecer parados, caminhar, correr, percorrer curvas e
ser removidos individualmente após o timeout.

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

Execute o workflow **Build CPM 0.0.8 Multi Remote** e baixe:

```text
CPM-Windows-0.0.8-Multi-Remote
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
powershell -ExecutionPolicy Bypass -File ".\tools\CPM-Multi-Remote-Test-0.0.8.ps1"
```

Cinco NPCs deverão ficar parados, caminhar, correr e percorrer curvas. Ao final,
o servidor removerá os jogadores por timeout e todos desaparecerão.

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
