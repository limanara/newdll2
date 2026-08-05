# CPM 0.0.3

Primeira base multijogador do CPM para Cyberpunk 2077. O cliente envia a
telemetria local, recebe estados remotos e o servidor nativo retransmite os
pacotes entre vários jogadores.

## Implementado

- `CPMClient.dll` com envio e recebimento UDP
- `CPMServer.exe` para múltiplos jogadores
- IDs únicos por conexão
- Relay de posição, rotação e velocidade
- Timeout de 10 segundos e aviso de desconexão
- Simulador PowerShell de um segundo jogador
- Telemetria local a 20 atualizações por segundo

O jogador remoto ainda não aparece visualmente no jogo. Nesta versão ele é
confirmado pelo log do cliente; a criação do personagem remoto será a próxima
etapa.

## Requisitos

- Cyberpunk 2077 Steam 2.3
- RED4ext compatível
- redscript estável instalado

## Compilar

Envie o projeto para o GitHub e execute o workflow **Build CPM Client**. Baixe
o artefato `CPM-Windows-0.0.3`.

## Instalar o cliente

Copie as pastas `red4ext` e `r6` do artefato para:

```text
D:\SteamLibrary\steamapps\common\Cyberpunk 2077
```

Mantenha `%LOCALAPPDATA%\CPM\connection.json` apontando para `127.0.0.1` e
porta `11777`.

## Testar dois jogadores

1. Execute o servidor:

```powershell
.\CPMServer.exe
```

2. Abra o Cyberpunk e carregue um save.
3. Em outro PowerShell, execute:

```powershell
powershell -ExecutionPolicy Bypass -File ".\tools\CPM-Player-Simulator-0.0.3.ps1"
```

4. Consulte o log do cliente:

```powershell
Get-Content "$env:LOCALAPPDATA\CPM\logs\CPMClient.log" -Wait -Tail 30
```

O resultado esperado contém:

```text
Remoto 2 | Seq 20 | X ... Y ... Z ... | Rot ... | Vel 2.00
```

O servidor também exibirá dois jogadores conectados. Depois que o simulador
terminar, o servidor enviará a desconexão por timeout.
