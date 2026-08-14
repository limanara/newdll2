$ErrorActionPreference = "Stop"

function New-CPMPacket([uint16]$type, [uint32]$size) {
    $data = [System.Collections.Generic.List[byte]]::new()
    $data.AddRange([BitConverter]::GetBytes([uint32]0x43435954))
    $data.AddRange([BitConverter]::GetBytes([uint16]1))
    $data.AddRange([BitConverter]::GetBytes($type))
    $data.AddRange([BitConverter]::GetBytes($size))
    return ,$data
}

$players = @()
for ($slot = 0; $slot -lt 5; $slot++) {
    $udp = [System.Net.Sockets.UdpClient]::new()
    $udp.Connect("127.0.0.1", 11777)
    $udp.Client.ReceiveTimeout = 3000
    [uint64]$token = (([uint64](Get-Random -Minimum 1 -Maximum 2147483647)) -shl 32) -bor ([uint64](Get-Random -Minimum 1 -Maximum 2147483647))
    $hello = New-CPMPacket 1 8
    $hello.AddRange([BitConverter]::GetBytes($token))
    [void]$udp.Send($hello.ToArray(), $hello.Count)
    $endpoint = [System.Net.IPEndPoint]::new([System.Net.IPAddress]::Any, 0)
    $welcome = $udp.Receive([ref]$endpoint)
    if ($welcome.Length -ne 16 -or [BitConverter]::ToUInt16($welcome, 6) -ne 2) { throw "Handshake CPM falhou no slot $slot." }
    $players += [pscustomobject]@{
        Udp = $udp
        Token = $token
        Id = [BitConverter]::ToUInt32($welcome, 12)
        Slot = $slot
        Clock = [Diagnostics.Stopwatch]::StartNew()
    }
}

Write-Host "CPM 0.0.8: cinco jogadores remotos conectados." -ForegroundColor Green
Write-Host "Eles devem aparecer juntos, mover-se com fluidez e desaparecer no timeout." -ForegroundColor Cyan

for ([uint32]$sequence = 0; $sequence -lt 900; $sequence++) {
    foreach ($player in $players) {
        if (($sequence % 20) -eq 0) {
            $heartbeat = New-CPMPacket 5 20
            $heartbeat.AddRange([BitConverter]::GetBytes([uint32]$player.Id))
            $heartbeat.AddRange([BitConverter]::GetBytes([uint64]$player.Token))
            $heartbeat.AddRange([BitConverter]::GetBytes([uint64]$player.Clock.ElapsedMilliseconds))
            [void]$player.Udp.Send($heartbeat.ToArray(), $heartbeat.Count)
        }

        $phase = ($player.Slot * 0.65)
        if ($sequence -lt 60) {
            [single]$x = 0.0; [single]$y = 0.0; [single]$yaw = 0.0; [single]$speed = 0.0
        } elseif ($sequence -lt 260) {
            [single]$x = ($sequence - 60) * (0.045 + $player.Slot * 0.004)
            [single]$y = [Math]::Sin($phase) * 0.5
            [single]$yaw = 0.0; [single]$speed = 2.0 + $player.Slot * 0.12
        } elseif ($sequence -lt 420) {
            [single]$x = 9.0 + (($sequence - 260) * (0.11 + $player.Slot * 0.006))
            [single]$y = [Math]::Sin($phase) * 0.5
            [single]$yaw = 0.0; [single]$speed = 5.5 + $player.Slot * 0.18
        } else {
            $angle = ($sequence - 420) * 0.022 + $phase
            [single]$x = 26.5 + ([Math]::Cos($angle) * (5.0 + $player.Slot * 0.35))
            [single]$y = [Math]::Sin($angle) * (5.0 + $player.Slot * 0.35)
            [single]$yaw = (($angle * 57.2957795) + 90.0) % 360.0
            [single]$speed = 3.0 + $player.Slot * 0.15
        }

        [single]$z = 0.0
        $packet = New-CPMPacket 3 29
        $packet.AddRange([BitConverter]::GetBytes([uint32]$player.Id))
        $packet.AddRange([BitConverter]::GetBytes($sequence))
        $packet.AddRange([BitConverter]::GetBytes($x))
        $packet.AddRange([BitConverter]::GetBytes($y))
        $packet.AddRange([BitConverter]::GetBytes($z))
        $packet.AddRange([BitConverter]::GetBytes($yaw))
        $packet.AddRange([BitConverter]::GetBytes($speed))
        $packet.Add([byte]0)
        [void]$player.Udp.Send($packet.ToArray(), $packet.Count)
    }
    Start-Sleep -Milliseconds 50
}

foreach ($player in $players) { $player.Udp.Dispose() }
Write-Host "Teste finalizado. Os cinco NPCs devem desaparecer apos o timeout." -ForegroundColor Green
