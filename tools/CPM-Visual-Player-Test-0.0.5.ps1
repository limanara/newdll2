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

Write-Host "CPM 0.0.5: Player visual $playerId conectado." -ForegroundColor Green
Write-Host "Procure o NPC perto de X -642, Y 812, Z 128.25. Teste de 60 segundos." -ForegroundColor Cyan
$clock = [Diagnostics.Stopwatch]::StartNew()

for ([uint32]$sequence = 0; $sequence -lt 1200; $sequence++) {
    if (($sequence % 40) -eq 0) {
        $heartbeat = New-CPMPacket 5 20
        $heartbeat.AddRange([BitConverter]::GetBytes([uint32]$playerId))
        $heartbeat.AddRange([BitConverter]::GetBytes([uint64]$token))
        $heartbeat.AddRange([BitConverter]::GetBytes([uint64]$clock.ElapsedMilliseconds))
        [void]$udp.Send($heartbeat.ToArray(), $heartbeat.Count)
    }

    $angle = $sequence * 0.02
    [single]$x = -642.0 + [Math]::Cos($angle) * 4.0
    [single]$y = 812.0 + [Math]::Sin($angle) * 4.0
    [single]$z = 128.25
    [single]$yaw = (($angle * 57.2957795) + 90.0) % 360.0
    [single]$speed = 2.0
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
