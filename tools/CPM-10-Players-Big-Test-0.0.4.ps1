$ErrorActionPreference = "Stop"
$serverAddress = "127.0.0.1"
$serverPort = 11777
$playerCount = 10
$clients = [System.Collections.Generic.List[object]]::new()

function New-Packet([uint16]$type, [uint32]$size) {
    $bytes = [System.Collections.Generic.List[byte]]::new()
    $bytes.AddRange([BitConverter]::GetBytes([uint32]0x43435954))
    $bytes.AddRange([BitConverter]::GetBytes([uint16]1))
    $bytes.AddRange([BitConverter]::GetBytes($type))
    $bytes.AddRange([BitConverter]::GetBytes($size))
    return ,$bytes
}

Write-Host "CPM 0.0.4 - conectando $playerCount jogadores simulados..." -ForegroundColor Cyan
for ($i = 0; $i -lt $playerCount; $i++) {
    $udp = [System.Net.Sockets.UdpClient]::new()
    $udp.Connect($serverAddress, $serverPort)
    $udp.Client.ReceiveTimeout = 3000
    [uint64]$token = (([uint64](Get-Random -Minimum 1 -Maximum 2147483647)) -shl 32) -bor ([uint64](Get-Random -Minimum 1 -Maximum 2147483647))
    $hello = New-Packet 1 8
    $hello.AddRange([BitConverter]::GetBytes($token))
    [void]$udp.Send($hello.ToArray(), $hello.Count)
    $remote = [System.Net.IPEndPoint]::new([System.Net.IPAddress]::Any, 0)
    $welcome = $udp.Receive([ref]$remote)
    if ($welcome.Length -ne 16 -or [BitConverter]::ToUInt16($welcome, 6) -ne 2) { throw "Handshake do simulador $i falhou." }
    $id = [BitConverter]::ToUInt32($welcome, 12)
    $clients.Add([pscustomobject]@{ Udp = $udp; Id = $id; Token = $token; Index = $i })
    Write-Host "Player simulado $id conectado."
}

Write-Host "Enviando movimento, 5% de perda simulada e uma pausa de telemetria protegida por heartbeat..." -ForegroundColor Green
$stopwatch = [Diagnostics.Stopwatch]::StartNew()
for ([uint32]$sequence = 0; $sequence -lt 1200; $sequence++) {
    foreach ($client in $clients) {
        if (($sequence % 40) -eq 0) {
            $heartbeat = New-Packet 5 20
            $heartbeat.AddRange([BitConverter]::GetBytes([uint32]$client.Id))
            $heartbeat.AddRange([BitConverter]::GetBytes([uint64]$client.Token))
            $heartbeat.AddRange([BitConverter]::GetBytes([uint64]$stopwatch.ElapsedMilliseconds))
            [void]$client.Udp.Send($heartbeat.ToArray(), $heartbeat.Count)
        }
        if ($sequence -ge 400 -and $sequence -lt 640) { continue }
        if ((($sequence + $client.Index) % 20) -eq 0) { continue }
        $angle = ($sequence * 0.025) + ($client.Index * 0.55)
        [single]$x = -642.0 + [Math]::Cos($angle) * (6.0 + $client.Index)
        [single]$y = 812.0 + [Math]::Sin($angle) * (6.0 + $client.Index)
        [single]$z = 128.25
        [single]$yaw = (($angle * 57.2957795) % 360.0)
        [single]$speed = 2.0 + ($client.Index * 0.15)
        $packet = New-Packet 3 29
        $packet.AddRange([BitConverter]::GetBytes([uint32]$client.Id))
        $packet.AddRange([BitConverter]::GetBytes($sequence))
        $packet.AddRange([BitConverter]::GetBytes($x))
        $packet.AddRange([BitConverter]::GetBytes($y))
        $packet.AddRange([BitConverter]::GetBytes($z))
        $packet.AddRange([BitConverter]::GetBytes($yaw))
        $packet.AddRange([BitConverter]::GetBytes($speed))
        $packet.Add([byte]0)
        [void]$client.Udp.Send($packet.ToArray(), $packet.Count)
    }
    if (($sequence % 100) -eq 0) { Write-Host "Sequencia $sequence/1200" }
    Start-Sleep -Milliseconds 50
}

foreach ($client in $clients) { $client.Udp.Dispose() }
Write-Host "BIG TEST FINALIZADO: $playerCount simuladores, movimento, perda e heartbeat testados." -ForegroundColor Green
