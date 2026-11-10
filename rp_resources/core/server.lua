-- Contrato planejado para o runtime Lua do CPM RP.
-- Este arquivo NAO e executado ate a integracao do interpretador Lua no servidor C++.
local players = {}

AddEventHandler("playerConnecting", function(playerId)
    players[playerId] = { id = playerId, authenticated = false }
    print(("[CPM RP] Jogador %d conectado"):format(playerId))
end)

AddEventHandler("playerDropped", function(playerId)
    players[playerId] = nil
end)

RegisterCommand("players", function(source)
    local count = 0
    for _ in pairs(players) do count = count + 1 end
    print(("[CPM RP] Online: %d"):format(count))
end, true)
