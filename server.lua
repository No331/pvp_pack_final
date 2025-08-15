-- server.lua for pvp_pack
local players = {}
local arenaPlayers = {}

-- helper to get arena data
local function getArena(index)
    return Config.Arenas[index]
end

-- renvoie si un joueur est en arène
local function isInArena(src)
    return players[src] and players[src].arena ~= nil
end

RegisterNetEvent('pvp:joinArena')
AddEventHandler('pvp:joinArena', function(arenaIndex)
    local src = source
    print("Server: Received joinArena request from player " .. src .. " for arena " .. tostring(arenaIndex))
    local a = getArena(arenaIndex)
    
    if not a then 
        print("Server: Arena " .. tostring(arenaIndex) .. " not found")
        print("Server: Available arenas:", json.encode(Config.Arenas))
        return 
    end
    
    print("Server: Arena found:", json.encode(a))
    
    -- Initialiser le joueur
    players[src] = {arena = arenaIndex, kills = 0, deaths = 0, vMenuDisabled = true}
    arenaPlayers[arenaIndex] = arenaPlayers[arenaIndex] or {}
    arenaPlayers[arenaIndex][src] = true
    
    print("Server: Player " .. src .. " joining arena " .. a.name)
    
    -- Téléporter le joueur et donner l'arme
    print("Server: Triggering forceJoinClient for player " .. src)
    TriggerClientEvent('pvp:forceJoinClient', src, arenaIndex, a)
end)

RegisterNetEvent('pvp:playerEnteredArena')
AddEventHandler('pvp:playerEnteredArena', function(arenaIndex)
    local src = source
    print("Server: Player " .. src .. " entered arena " .. tostring(arenaIndex))
    players[src] = players[src] or {arena = arenaIndex, kills = 0, deaths = 0, vMenuDisabled = true}
end)

RegisterNetEvent('pvp:playerDied')
AddEventHandler('pvp:playerDied', function(killerServerId, arenaIndex)
    local victim = source
    arenaIndex = arenaIndex or (players[victim] and players[victim].arena)
    if not arenaIndex then return end

    players[victim] = players[victim] or {arena = arenaIndex, kills = 0, deaths = 0, vMenuDisabled = true}
    players[victim].deaths = players[victim].deaths + 1

    print("Server: Player " .. victim .. " died in arena " .. tostring(arenaIndex))

    -- if killer is valid and tracked, award kill
    if killerServerId and killerServerId ~= 0 and players[killerServerId] then
        players[killerServerId].kills = players[killerServerId].kills + 1
        print("Server: Player " .. killerServerId .. " got a kill")
        -- update killer HUD
        TriggerClientEvent('pvp:updateHud', killerServerId, players[killerServerId].kills, players[killerServerId].deaths)
    end

    -- update victim HUD
    TriggerClientEvent('pvp:updateHud', victim, players[victim].kills, players[victim].deaths)

    -- respawn victim in arena
    local a = getArena(arenaIndex)
    if a then
        TriggerClientEvent('pvp:respawnInArenaClient', victim, arenaIndex, a)
    end
end)

-- Commande serveur pour bloquer vMenu/noclip
RegisterCommand("checkVMenu", function(source, args, raw)
    local src = source
    if isInArena(src) then
        TriggerClientEvent('vMenu:disableMenu', src, true)
    else
        TriggerClientEvent('vMenu:disableMenu', src, false)
    end
end, false)

AddEventHandler('playerDropped', function(reason)
    local src = source
    if players[src] then
        local arena = players[src].arena
        if arena and arenaPlayers[arena] then
            arenaPlayers[arena][src] = nil
        end
        players[src] = nil
        print("Server: Player " .. src .. " disconnected and removed from PvP")
    end
end)

-- Boucle serveur pour maintenir vMenu désactivé si joueur en arène
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(5000) -- check toutes les 5 secondes
        for src,_ in pairs(players) do
            if isInArena(src) then
                TriggerClientEvent('vMenu:disableMenu', src, true)
            end
        end
    end
end)