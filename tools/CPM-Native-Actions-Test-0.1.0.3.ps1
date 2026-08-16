$ErrorActionPreference = "Stop"

function New-CPMPacket([uint16]$type, [uint32]$size) {
    $data = [System.Collections.Generic.List[byte]]::new()
    $data.AddRange([BitConverter]::GetBytes([uint32]0x43435954))
    $data.AddRange([BitConverter]::GetBytes([uint16]2))
    $data.AddRange([BitConverter]::GetBytes($type))
    $data.AddRange([BitConverter]::GetBytes($size))
    return ,$data
}

function Send-State($player,[uint32]$sequence,[single]$x,[single]$y,[single]$z,[single]$yaw,[single]$speed,
    [int16]$locomotion,[int16]$detailed,[int16]$upperBody,[int16]$weaponState,[int16]$meleeState,
    [int16]$weaponType,[uint16]$flags,[uint32]$shotEvent,[uint32]$reloadEvent,[uint32]$meleeEvent) {
    $radians=$yaw*[Math]::PI/180.0
    [single]$aimX=[Math]::Cos($radians);[single]$aimY=[Math]::Sin($radians);[single]$aimZ=0.05
    $packet=New-CPMPacket 3 66
    $packet.AddRange([BitConverter]::GetBytes([uint32]$player.Id));$packet.AddRange([BitConverter]::GetBytes($sequence))
    foreach($value in @($x,$y,$z,$yaw,$speed,$aimX,$aimY,$aimZ)){$packet.AddRange([BitConverter]::GetBytes([single]$value))}
    foreach($value in @($locomotion,$detailed,$upperBody,$weaponState,$meleeState,$weaponType)){$packet.AddRange([BitConverter]::GetBytes([int16]$value))}
    $packet.AddRange([BitConverter]::GetBytes($flags))
    foreach($value in @($shotEvent,$reloadEvent,$meleeEvent)){$packet.AddRange([BitConverter]::GetBytes([uint32]$value))}
    if($packet.Count-ne 78){throw "Pacote invalido: $($packet.Count) bytes."}
    [void]$player.Udp.Send($packet.ToArray(),$packet.Count)
}

$udp=[System.Net.Sockets.UdpClient]::new();$udp.Connect("127.0.0.1",11777);$udp.Client.ReceiveTimeout=3000
[uint64]$token=(([uint64](Get-Random -Minimum 1 -Maximum 2147483647))-shl 32)-bor([uint64](Get-Random -Minimum 1 -Maximum 2147483647))
$hello=New-CPMPacket 1 8;$hello.AddRange([BitConverter]::GetBytes($token));[void]$udp.Send($hello.ToArray(),$hello.Count)
$endpoint=[System.Net.IPEndPoint]::new([System.Net.IPAddress]::Any,0);$welcome=$udp.Receive([ref]$endpoint)
if($welcome.Length-ne 16-or[BitConverter]::ToUInt16($welcome,6)-ne 2){throw "Handshake CPM 0.1.0.3 falhou."}
$player=[pscustomobject]@{Udp=$udp;Token=$token;Id=[BitConverter]::ToUInt32($welcome,12);Clock=[Diagnostics.Stopwatch]::StartNew()}

Write-Host "CPM 0.1.0.3: Native Actions iniciado." -ForegroundColor Green
Write-Host "O NPC volta para perto antes de testar mira, tiro, recarga e melee." -ForegroundColor Cyan
[uint32]$shot=0;[uint32]$reload=0;[uint32]$melee=0;$lastPhase=""

for([uint32]$seq=0; $seq -lt 1500; $seq++){
    if(($seq%20) -eq 0){$heartbeat=New-CPMPacket 5 20;$heartbeat.AddRange([BitConverter]::GetBytes([uint32]$player.Id));$heartbeat.AddRange([BitConverter]::GetBytes([uint64]$player.Token));$heartbeat.AddRange([BitConverter]::GetBytes([uint64]$player.Clock.ElapsedMilliseconds));[void]$udp.Send($heartbeat.ToArray(),$heartbeat.Count)}
    [single]$x=0;[single]$y=0;[single]$z=0;[single]$yaw=0;[single]$speed=0
    [int16]$loc=0;[int16]$detail=1;[int16]$upper=0;[int16]$weaponState=0;[int16]$meleeState=22;[int16]$weaponType=2;[uint16]$flags=0
    if($seq -lt 80){$phase="PARADO";$x=0}
    elseif($seq -lt 260){$phase="CAMINHADA";$x=($seq-80)*0.045;$speed=2.0}
    elseif($seq -lt 400){$phase="CORRIDA";$x=8.1+($seq-260)*0.11;$speed=5.5;$loc=2;$detail=4}
    elseif($seq -lt 520){$phase="AGACHADO";$x=23.5+($seq-400)*0.025;$speed=1.2;$loc=1;$detail=3}
    elseif($seq -lt 600){$phase="PARADO ANTES DO SALTO";$x=26.5}
    elseif($seq -lt 640){$phase="SALTO";$x=26.5+($seq-600)*0.04;$z=(($seq-600)/40.0)*1.35;$speed=2.0;$detail=18}
    elseif($seq -lt 680){$phase="QUEDA";$x=28.1+($seq-640)*0.04;$z=(1.0-(($seq-640)/40.0))*1.35;$speed=2.0;$detail=14}
    elseif($seq -lt 740){$phase="ATERRISSAGEM";$x=29.7;$detail=23}
    elseif($seq -lt 1000){$phase="RETORNO PARA COMBATE";$x=29.7-(($seq-740)*0.099);$yaw=180;$speed=5.5;$loc=2;$detail=4}
    elseif($seq -lt 1080){$phase="EQUIPANDO ARMA";$x=4.0;$flags=1;$weaponState=5}
    elseif($seq -lt 1240){$phase="MIRA E TIROS";$x=4.0;$yaw=180;$flags=3;$upper=6;$weaponState=5
        if($seq -eq 1120 -or $seq -eq 1160 -or $seq -eq 1200){$shot++;$weaponState=8}}
    elseif($seq -lt 1320){$phase="RECARGA";$x=4.0;$yaw=180;$flags=1;$upper=3;$weaponState=2;if($seq -eq 1240){$reload++}}
    elseif($seq -lt 1420){$phase="ATAQUE CORPO A CORPO";$x=2.2;$yaw=180;$flags=1;$meleeState=11;if($seq -eq 1320 -or $seq -eq 1370){$melee++}}
    else{$phase="FINAL PARADO";$x=4.0}
    if($phase -ne $lastPhase){Write-Host "`nFASE: $phase | Seq $seq" -ForegroundColor Yellow;$lastPhase=$phase}
    Send-State $player $seq $x $y $z $yaw $speed $loc $detail $upper $weaponState $meleeState $weaponType $flags $shot $reload $melee
    Start-Sleep -Milliseconds 50
}
$udp.Dispose();Write-Host "Teste 0.1.0.3 finalizado. O NPC deve desaparecer apos o timeout." -ForegroundColor Green
