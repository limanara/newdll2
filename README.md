# CPM 0.0.5 — Protótipo visual

Primeira versão que transforma o estado remoto recebido pela DLL em uma
entidade visível dentro do Cyberpunk 2077.

## O que esta versão testa

- API nativa de consulta dos jogadores remotos
- criação segura de uma entidade dinâmica pelo Codeware
- modelo humano padrão para o primeiro jogador remoto
- atualização de posição e rotação a cada 50 ms
- remoção automática da entidade após a desconexão
- toda a rede, sessões, heartbeat e reconexão do CPM 0.0.4

Nesta etapa somente o primeiro jogador remoto é renderizado. A entidade ainda
não possui animação multiplayer, aparência personalizada, colisão própria nem
interpolação. Ela será reposicionada diretamente e poderá parecer deslizar.

## Requisitos

- Cyberpunk 2077 Steam 2.3
- RED4ext compatível
- redscript estável
- Codeware compatível instalado
- `%LOCALAPPDATA%\CPM\connection.json` apontando para `127.0.0.1:11777`

O Codeware não está incluído neste pacote. Instale-o na raiz do jogo antes de
instalar o CPM. Sem ele, o redscript informará que `DynamicEntitySystem` não
existe e o jogo não carregará o script.

## Compilação no GitHub

Execute o workflow **Build CPM 0.0.5 Visual Prototype** e baixe:

```text
CPM-Windows-0.0.5-Visual-Prototype
```

## Instalação

Copie as pastas `red4ext` e `r6` do artefato para a raiz:

```text
D:\SteamLibrary\steamapps\common\Cyberpunk 2077
```

Aceite substituir `CPMClient.dll` e `CPMClient.reds`.

## Teste visual

1. Feche o jogo e qualquer servidor CPM antigo.
2. Inicie `CPMServer.exe`.
3. Abra o Cyberpunk e carregue um save.
   Use um save de teste: o modelo desta fase é apenas um marcador visual e
   ainda conserva comportamentos nativos de NPC.
4. Fique próximo das coordenadas `X -642, Y 812, Z 128` usadas nos testes
   anteriores.
5. Em outro PowerShell, execute:

```powershell
powershell -ExecutionPolicy Bypass -File ".\tools\CPM-Visual-Player-Test-0.0.5.ps1"
```

Um NPC deverá aparecer e percorrer um círculo por 60 segundos. Ao final, o
servidor removerá o jogador por timeout e o NPC desaparecerá em até 15 segundos.

## Diagnóstico

Log do cliente:

```powershell
Get-Content "$env:LOCALAPPDATA\CPM\logs\CPMClient.log" -Wait -Tail 60
```

Log do redscript:

```powershell
Get-Content "D:\SteamLibrary\steamapps\common\Cyberpunk 2077\r6\logs\redscript.log" -Tail 100
```

Se ocorrer erro de script, envie as últimas linhas de `redscript.log`. Se o
jogo abrir mas o NPC não aparecer, envie também `CPMClient.log` e a saída do
servidor.
