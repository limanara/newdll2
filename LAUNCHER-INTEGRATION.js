// Adicione esta função ao processo principal do CPM Launcher e chame-a
// imediatamente antes de abrir steam://rungameid/1091500.
const fs = require('fs');
const path = require('path');
function writeCPMConnection(server) {
  if (!server?.ip || !server?.port) throw new Error('Servidor CPM inválido');
  const folder = path.join(process.env.LOCALAPPDATA, 'CPM');
  fs.mkdirSync(folder, { recursive: true });
  fs.writeFileSync(path.join(folder, 'connection.json'), JSON.stringify({
    address: server.ip,
    port: Number(server.port),
    protocolVersion: 1,
    serverName: server.name || `${server.ip}:${server.port}`,
    selectedAt: new Date().toISOString()
  }, null, 2));
}
