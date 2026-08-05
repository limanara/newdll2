# CPM 0.0.4 — Big Test

Versão integrada para validar a fundação multiplayer do CPM antes da criação
visual dos jogadores remotos.

## Funcionalidades

- Heartbeat nativo a cada 2 segundos, independente do redscript
- Ping/pong e medição de latência
- Reconexão automática quando o servidor deixa de responder
- Sessão identificada por token aleatório
- Player ID preservado quando endereço ou porta UDP mudam
- Registro e snapshots de vários jogadores remotos na DLL
- Detecção aproximada de perda e sequência de pacotes
- Normalização da rotação entre 0 e 360 graus
- Servidor com sessões preservadas, métricas e validação
- Estado atual enviado imediatamente para novos jogadores
- Simulador integrado de 10 jogadores
- Teste de 5% de perda e pausa de telemetria protegida pelo heartbeat

Esta versão ainda não cria personagens remotos visíveis. Ela valida rede,
sessões e estabilidade antes da integração de entidades da engine.

## Requisitos

- Cyberpunk 2077 Steam 2.3
- RED4ext compatível
- redscript estável instalado
- `%LOCALAPPDATA%\CPM\connection.json` apontando para `127.0.0.1:11777`

## Compilação

Execute o workflow **Build CPM 0.0.4** e baixe o artefato:

```text
CPM-Windows-0.0.4-Big-Test
```

## Instalação

Copie as pastas `red4ext` e `r6` para:

```text
D:\SteamLibrary\steamapps\common\Cyberpunk 2077
```

Aceite substituir `CPMClient.dll` e `CPMClient.reds`.

## Grande teste

Feche qualquer servidor CPM antigo. Abra o PowerShell na raiz do artefato e
execute:

```powershell
powershell -ExecutionPolicy Bypass -File ".\Start-Big-Test.ps1"
```

O script iniciará o servidor. Abra o Cyberpunk, carregue o save e pressione
ENTER na janela do teste. Dez jogadores serão simulados durante cerca de um
minuto.

## Resultado esperado

Servidor:

```text
STATUS | ativos 11 | sessoes 11 | recebidos ... | relay ... | invalidos 0
```

Log `%LOCALAPPDATA%\CPM\logs\CPMClient.log`:

```text
Status | Conectado sim | Ping ... ms | Remotos 10 | Enviados ... | Recebidos ...
Remoto ... | Seq ... | X ... Y ... Z ... | Rot ... | Vel ...
```

Durante a pausa artificial de 12 segundos, os simuladores devem permanecer
ativos graças ao heartbeat. A perda remota será maior que zero porque o teste
remove propositalmente 5% dos pacotes.
