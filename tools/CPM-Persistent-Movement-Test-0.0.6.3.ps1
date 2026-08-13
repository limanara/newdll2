$ErrorActionPreference = "Stop"
$udp = [System.Net.Sockets.UdpClient]::new()
$udp.Connect("127.0.0.1", 11777)
$udp.Client.ReceiveTimeout = 3000

function New-CPMPacket([uint16]$type, [uint32]$size) {
    $data = [System.Collections.Generic.List[byte]]::new()
    $data.AddRange([BitConverter]::GetBytes([uint32]0x43435954))
    $data.AddRange([BitConverter]::GetBytes([uint16]1))
    $data.AddRange([BitConverter]::GetBytes($type))
    $data.AddRange([BitConverter]::GetBytes($size))
    return ,$data
}

[uint64]$token = (([uint64](Get-Random -Minimum 1 -Maximum 2147483647)) -shl 32) -bor ([uint64](Get-Random -Minimum 1 -Maximum 2147483647))
$hello = New-CPMPacket 1 8
$hello.AddRange([BitConverter]::GetBytes($token))
[void]$udp.Send($hello.ToArray(), $hello.Count)
$remote = [System.Net.IPEndPoint]::new([System.Net.IPAddress]::Any, 0)
$welcome = $udp.Receive([ref]$remote)
if ($welcome.Length -ne 16 -or [BitConverter]::ToUInt16($welcome, 6) -ne 2) { throw "Handshake CPM falhou." }
$playerId = [BitConverter]::ToUInt32($welcome, 12)

Write-Host "CPM 0.0.6.3: Player visual $playerId conectado." -ForegroundColor Green
Write-Host "O NPC sera criado perto da posicao atual do seu personagem." -ForegroundColor Cyan
Write-Host "Fases: parado, caminhada, corrida, circulo e correcao." -ForegroundColor Cyan
$clock = [Diagnostics.Stopwatch]::StartNew()

for ([uint32]$sequence = 0; $sequence -lt 900; $sequence++) {
    if (($sequence % 20) -eq 0) {
        $heartbeat = New-CPMPacket 5 20
        $heartbeat.AddRange([BitConverter]::GetBytes([uint32]$playerId))
        $heartbeat.AddRange([BitConverter]::GetBytes([uint64]$token))
        $heartbeat.AddRange([BitConverter]::GetBytes([uint64]$clock.ElapsedMilliseconds))
        [void]$udp.Send($heartbeat.ToArray(), $heartbeat.Count)
    }

    # Coordenadas virtuais: o cliente usa apenas a diferenca entre os pacotes
    # e ancora o movimento na posicao atual do jogador real.
    if ($sequence -lt 60) {
        # 3 segundos parado: valida idle e estabilidade.
        [single]$x = 0.0
        [single]$y = 0.0
        [single]$yaw = 0.0
        [single]$speed = 0.0
    } elseif ($sequence -lt 220) {
        # 8 segundos caminhando continuamente em linha reta.
        [single]$x = ($sequence - 60) * 0.06
        [single]$y = 0.0
        [single]$yaw = 0.0
        [single]$speed = 2.0
    } elseif ($sequence -lt 340) {
        # 6 segundos correndo continuamente, sem salto entre as fases.
        [single]$x = 9.6 + (($sequence - 220) * 0.15)
        [single]$y = 0.0
        [single]$yaw = 0.0
        [single]$speed = 6.0
    } else {
        # 28 segundos em curva: comeca exatamente no fim da corrida.
        $angle = ($sequence - 340) * 0.025
        [single]$x = 21.6 + ([Math]::Cos($angle) * 6.0)
        [single]$y = [Math]::Sin($angle) * 6.0
        [single]$yaw = (($angle * 57.2957795) + 90.0) % 360.0
        [single]$speed = 3.0
    }
    [single]$z = 0.0
    $packet = New-CPMPacket 3 29
    $packet.AddRange([BitConverter]::GetBytes([uint32]$playerId))
    $packet.AddRange([BitConverter]::GetBytes($sequence))
    $packet.AddRange([BitConverter]::GetBytes($x))
    $packet.AddRange([BitConverter]::GetBytes($y))
    $packet.AddRange([BitConverter]::GetBytes($z))
    $packet.AddRange([BitConverter]::GetBytes($yaw))
    $packet.AddRange([BitConverter]::GetBytes($speed))
    $packet.Add([byte]0)
    [void]$udp.Send($packet.ToArray(), $packet.Count)
    Start-Sleep -Milliseconds 50
}

$udp.Dispose()
Write-Host "Teste visual finalizado. O NPC deve desaparecer após o timeout." -ForegroundColor Green
