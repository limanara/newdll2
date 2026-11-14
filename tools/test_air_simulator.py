"""Exercise the real PowerShell serializer against an isolated UDP receiver.
Does not start the game/server or write to their installation.
"""
import pathlib
import socket
import struct
import subprocess

HEADER = struct.Struct('<IHHI')
STATE = struct.Struct('<II8f6hH3I')
script = pathlib.Path(__file__).with_name('CPM-Physical-Air-Test-0.3.0.0.ps1')

with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as receiver:
    receiver.bind(('127.0.0.1', 0))
    receiver.settimeout(10)
    process = subprocess.Popen([
        'powershell.exe', '-NoProfile', '-ExecutionPolicy', 'Bypass',
        '-File', str(script), '-AirOnly', '-Port', str(receiver.getsockname()[1]),
    ], stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    samples = []
    try:
        while len(samples) < 160:
            packet, endpoint = receiver.recvfrom(512)
            magic, version, kind, size = HEADER.unpack_from(packet)
            assert (magic, version) == (0x43435954, 2)
            assert len(packet) == HEADER.size + size
            if kind == 7:
                receiver.sendto(HEADER.pack(magic, version, 8, 16) +
                                struct.pack('<4f', 100, 200, 10, 0), endpoint)
            elif kind == 1:
                receiver.sendto(HEADER.pack(magic, version, 2, 4) +
                                struct.pack('<I', 42), endpoint)
            elif kind == 3:
                assert size == STATE.size == 66
                samples.append(STATE.unpack_from(packet, HEADER.size))
            else:
                assert kind == 5 and size == 20
        output, _ = process.communicate(timeout=10)
        assert process.returncode == 0, output
        assert [s[1] for s in samples] == list(range(160))
        for offset in (0, 80):
            jump = samples[offset:offset + 80]
            assert all(s[0] == 42 and abs(s[2] - 103) < 0.001 and s[3] == 200 for s in jump)
            assert [jump[i][11] for i in (0, 20, 35, 50, 60)] == [1, 18, 14, 23, 1]
            assert abs(max(s[4] for s in jump) - 11.15) < 0.001
            assert jump[0][4] == jump[-1][4] == 10
            assert all(jump[i][4] <= jump[i + 1][4] for i in range(20, 35))
            assert all(jump[i][4] >= jump[i + 1][4] for i in range(35, 50))
        print('PASS: 160 packets, two complete jump arcs, v2/66-byte payload, ordered sequences.')
    finally:
        if process.poll() is None:
            process.kill()
            process.communicate()
