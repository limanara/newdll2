# CPM Client 0.0.2

Plugin experimental para Cyberpunk 2077 Steam 2.3 no Windows 10. Esta versão
mantém o handshake UDP da 0.0.1 e envia a posição do jogador ao servidor 20
vezes por segundo.

## Novidades

- Ponte redscript -> C++ usando RedLib
- Posição X, Y e Z do jogador
- Rotação horizontal em graus
- Velocidade estimada em unidades por segundo
- Número sequencial de cada pacote
- Servidor PowerShell 0.0.2 que mostra a telemetria

Esta versão ainda não cria outros jogadores dentro do jogo. O objetivo é
validar a captura e o transporte dos dados antes da sincronização visual.

## Requisitos no jogo

- Cyberpunk 2077 Steam 2.3
- RED4ext compatível e funcionando
- redscript compatível com o jogo

O CMake baixa automaticamente o RED4ext SDK e o RedLib durante a compilação.

## Compilar no GitHub Actions

1. Extraia este projeto.
2. Envie todo o conteúdo para a raiz do repositório GitHub.
3. Abra **Actions > Build CPM Client > Run workflow**.
4. Ao terminar, baixe o artefato **CPM-Client-Windows-0.0.2**.

## Instalar

Dentro do artefato, copie as pastas `red4ext` e `r6` para:

```text
D:\SteamLibrary\steamapps\common\Cyberpunk 2077
```

Confirme que estes arquivos existem:

```text
D:\SteamLibrary\steamapps\common\Cyberpunk 2077\red4ext\plugins\CPMClient\CPMClient.dll
D:\SteamLibrary\steamapps\common\Cyberpunk 2077\r6\scripts\CPM\CPMClient.reds
```

Mantenha o arquivo que já funcionou:

```text
%LOCALAPPDATA%\CPM\connection.json
```

## Testar

Abra o PowerShell na pasta `tools` do artefato e execute:

```powershell
powershell -ExecutionPolicy Bypass -File ".\CPM-Test-Server-0.0.2.ps1"
```

Depois abra o jogo, carregue um save e caminhe. O servidor deverá imprimir
linhas semelhantes a:

```text
Player 1 | Seq 20 | X -1450,21 Y 1134,80 Z 31,42 | Rot 92,5 | Vel 3,18
```

O log nativo fica em `%LOCALAPPDATA%\CPM\logs\CPMClient.log`. Se o jogo mostrar
erro ao compilar o script, consulte também os arquivos de log em
`Cyberpunk 2077\r6\logs`.

## Arquivo de conexão

Exemplo de `%LOCALAPPDATA%\CPM\connection.json`:

```json
{
  "address": "127.0.0.1",
  "port": 11777,
  "serverName": "CPM Test Server",
  "protocolVersion": 1
}
```
