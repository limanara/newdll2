$ErrorActionPreference = "Stop"

function New-CPMPacket([uint16]$type, [uint32]$size) {
    $data = [System.Collections.Generic.List[byte]]::new()
    $data.AddRange([BitConverter]::GetBytes([uint32]0x43435954))
    $data.AddRange([BitConverter]::GetBytes([uint16]2))
    $data.AddRange([BitConverter]::GetBytes($type))
    $data.AddRange([BitConverter]::GetBytes($size))
    return ,$data
}

function Send-State($player, [uint32]$sequence, [single]$x, [single]$y, [single]$z,
    [single]$yaw, [single]$speed, [int16]$locomotion, [int16]$detailed,
    [int16]$upperBody, [int16]$weaponState, [int16]$meleeState, [int16]$weaponType,
    [uint16]$flags, [uint32]$shotEvent, [uint32]$reloadEvent, [uint32]$meleeEvent) {
    $radians = $yaw * [Math]::PI / 180.0
    [single]$aimX = [Math]::Cos($radians)
    [single]$aimY = [Math]::Sin($radians)
    [single]$aimZ = 0.05
    $packet = New-CPMPacket 3 66
    $packet.AddRange([BitConverter]::GetBytes([uint32]$player.Id))
    $packet.AddRange([BitConverter]::GetBytes($sequence))
    foreach ($value in @($x,$y,$z,$yaw,$speed,$aimX,$aimY,$aimZ)) { $packet.AddRange([BitConverter]::GetBytes([single]$value)) }
    foreach ($value in @($locomotion,$detailed,$upperBody,$weaponState,$meleeState,$weaponType)) { $packet.AddRange([BitConverter]::GetBytes([int16]$value)) }
    $packet.AddRange([BitConverter]::GetBytes($flags))
    foreach ($value in @($shotEvent,$reloadEvent,$meleeEvent)) { $packet.AddRange([BitConverter]::GetBytes([uint32]$value)) }
    if ($packet.Count -ne 78) { throw "Pacote invalido: $($packet.Count) bytes; esperado 78." }
    [void]$player.Udp.Send($packet.ToArray(), $packet.Count)
}

$udp = [System.Net.Sockets.UdpClient]::new()
$udp.Connect("127.0.0.1",11777)
$udp.Client.ReceiveTimeout = 3000
[uint64]$token = (([uint64](Get-Random -Minimum 1 -Maximum 2147483647)) -shl 32) -bor ([uint64](Get-Random -Minimum 1 -Maximum 2147483647))
$hello = New-CPMPacket 1 8; $hello.AddRange([BitConverter]::GetBytes($token)); [void]$udp.Send($hello.ToArray(),$hello.Count)
$endpoint = [System.Net.IPEndPoint]::new([System.Net.IPAddress]::Any,0)
$welcome = $udp.Receive([ref]$endpoint)
if ($welcome.Length -ne 16 -or [BitConverter]::ToUInt16($welcome,6) -ne 2) { throw "Handshake CPM 0.1.0 falhou." }
$player = [pscustomobject]@{Udp=$udp;Token=$token;Id=[BitConverter]::ToUInt32($welcome,12);Clock=[Diagnostics.Stopwatch]::StartNew()}

Write-Host "CPM 0.1.0: teste combinado iniciado." -ForegroundColor Green
Write-Host "Observe: parado, caminhada, corrida, agachamento, salto/queda/pouso, mira, tiro, recarga e ataque corpo a corpo." -ForegroundColor Cyan

[uint32]$shot=0; [uint32]$reload=0; [uint32]$melee=0
for ([uint32]$seq=0; $seq -lt 1000; $seq++) {
    if (($seq % 20) -eq 0) {
        $heartbeat=New-CPMPacket 5 20
        $heartbeat.AddRange([BitConverter]::GetBytes([uint32]$player.Id));$heartbeat.AddRange([BitConverter]::GetBytes([uint64]$player.Token));$heartbeat.AddRange([BitConverter]::GetBytes([uint64]$player.Clock.ElapsedMilliseconds))
        [void]$udp.Send($heartbeat.ToArray(),$heartbeat.Count)
    }
    [single]$x=0;[single]$y=0;[single]$z=0;[single]$yaw=0;[single]$speed=0
    [int16]$loc=0;[int16]$detail=1;[int16]$upper=0;[int16]$weaponState=0;[int16]$meleeState=22;[int16]$weaponType=0;[uint16]$flags=0
    if ($seq -ge 80 -and $seq -lt 260) { $x=($seq-80)*0.045;$speed=2.0;$detail=1 }
    elseif ($seq -ge 260 -and $seq -lt 400) { $x=8.1+($seq-260)*0.11;$speed=5.5;$loc=2;$detail=4 }
    elseif ($seq -ge 400 -and $seq -lt 500) { $x=23.5+($seq-400)*0.025;$speed=1.2;$loc=1;$detail=3 }
    elseif ($seq -ge 500 -and $seq -lt 560) { $x=26.0+($seq-500)*0.04;$z=[Math]::Sin((($seq-500)/60.0)*[Math]::PI)*1.2;$speed=2.0;$detail=18 }
    elseif ($seq -ge 560 -and $seq -lt 600) { $x=28.4;$detail=23 }
    elseif ($seq -ge 600 -and $seq -lt 820) {
        $x=28.4+($seq-600)*0.018;$speed=0.8;$upper=6;$weaponState=5;$weaponType=2;$flags=3;$yaw=35
        if ($seq -eq 640 -or $seq -eq 680 -or $seq -eq 720) { $shot++;$weaponState=8 }
        if ($seq -ge 750 -and $seq -lt 790) { if ($seq -eq 750) {$reload++};$upper=3;$weaponState=2 }
    }
    elseif ($seq -ge 820 -and $seq -lt 900) { $x=32.4;$meleeState=11;if ($seq -eq 820 -or $seq -eq 860) {$melee++} }
    else { $x=32.4 }
    Send-State $player $seq $x $y $z $yaw $speed $loc $detail $upper $weaponState $meleeState $weaponType $flags $shot $reload $melee
    if (($seq % 100) -eq 0) { Write-Host "Seq $seq | loc $loc detail $detail upper $upper weapon $weaponState | tiro $shot recarga $reload melee $melee" }
    Start-Sleep -Milliseconds 50
}
$udp.Dispose()
Write-Host "Teste encerrado. O NPC deve desaparecer apos o timeout." -ForegroundColor Green
