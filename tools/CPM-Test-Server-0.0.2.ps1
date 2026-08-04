$ErrorActionPreference = "Stop"
$port = 11777
$magic = [uint32]0x43435954
$protocolVersion = [uint16]1
$udp = [System.Net.Sockets.UdpClient]::new($port)
$remote = [System.Net.IPEndPoint]::new([System.Net.IPAddress]::Any, 0)

function Add-UInt16LE([System.Collections.Generic.List[byte]]$bytes, [uint16]$value) {
    $bytes.AddRange([BitConverter]::GetBytes($value))
}
function Add-UInt32LE([System.Collections.Generic.List[byte]]$bytes, [uint32]$value) {
    $bytes.AddRange([BitConverter]::GetBytes($value))
}

Clear-Host
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "       CPM TEST SERVER 0.0.2" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Servidor iniciado na porta UDP $port"
Write-Host "Aguardando o CPM Client..."
Write-Host "Pressione CTRL + C para encerrar."
Write-Host ""

try {
    while ($true) {
        $packet = $udp.Receive([ref]$remote)
        if ($packet.Length -lt 12) { continue }
        $packetMagic = [BitConverter]::ToUInt32($packet, 0)
        $version = [BitConverter]::ToUInt16($packet, 4)
        $type = [BitConverter]::ToUInt16($packet, 6)
        $payloadSize = [BitConverter]::ToUInt32($packet, 8)
        if ($packetMagic -ne $magic -or $version -ne $protocolVersion) { continue }

        if ($type -eq 1 -and $payloadSize -eq 8 -and $packet.Length -eq 20) {
            Write-Host "Handshake CPM recebido de $($remote.Address):$($remote.Port)" -ForegroundColor Green
            $response = [System.Collections.Generic.List[byte]]::new()
            Add-UInt32LE $response $magic
            Add-UInt16LE $response $protocolVersion
            Add-UInt16LE $response 2
            Add-UInt32LE $response 4
            Add-UInt32LE $response 1
            [void]$udp.Send($response.ToArray(), $response.Count, $remote)
            Write-Host "Player ID 1 enviado ao cliente. Telemetria aguardada..." -ForegroundColor Green
            continue
        }

        if ($type -eq 3 -and $payloadSize -eq 29 -and $packet.Length -eq 41) {
            $playerId = [BitConverter]::ToUInt32($packet, 12)
            $sequence = [BitConverter]::ToUInt32($packet, 16)
            $x = [BitConverter]::ToSingle($packet, 20)
            $y = [BitConverter]::ToSingle($packet, 24)
            $z = [BitConverter]::ToSingle($packet, 28)
            $yaw = [BitConverter]::ToSingle($packet, 32)
            $speed = [BitConverter]::ToSingle($packet, 36)
            if (($sequence % 10) -eq 0) {
                Write-Host ("Player {0} | Seq {1} | X {2:N2} Y {3:N2} Z {4:N2} | Rot {5:N1} | Vel {6:N2}" -f $playerId,$sequence,$x,$y,$z,$yaw,$speed)
            }
        }
    }
}
finally {
    $udp.Dispose()
}
