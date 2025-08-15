-- =========================
--  Variables serveur optimisées
-- =========================
local PlayerManager = {
    players = {},
    arenaPlayers = {}
}

-- =========================
--  Utilitaires serveur
-- =========================
local function getArena(index)
    return Config.Arenas[index]
end

local function isInArena(src)
    return PlayerManager.players[src] and PlayerManager.players[src].arena ~= nil
end

local function initializePlayer(src, arenaIndex)
    PlayerManager.players[src] = {
        arena = arenaIndex,
        kills = 0,
        deaths = 0,
        vMenuDisabled = true
    }
    
    PlayerManager.arenaPlayers[arenaIndex] = PlayerManager.arenaPlayers[arenaIndex] or {}
    PlayerManager.arenaPlayers[arenaIndex][src] = true
    
    print("^2[PVP] Joueur " .. src .. " initialisé dans l'arène " .. arenaIndex .. "^0")
end

local function cleanupPlayer(src)
    if PlayerManager.players[src] then
        local arena = PlayerManager.players[src].arena
        if arena and PlayerManager.arenaPlayers[arena] then
            PlayerManager.arenaPlayers[arena][src] = nil
        end
        PlayerManager.players[src] = nil
        print("^3[PVP] Joueur " .. src .. " nettoyé^0")
    end
end

-- =========================
--  Gestionnaire d'arène serveur
-- =========================
local ArenaServerManager = {}

function ArenaServerManager.joinPlayer(src, arenaIndex)
    local arena = getArena(arenaIndex)
    if not arena then 
        print("^1[PVP] Arena " .. tostring(arenaIndex) .. " not found^0")
        return false
    end
    
    print("^2[PVP] Player " .. src .. " joining arena " .. arena.name .. "^0")
    
    initializePlayer(src, arenaIndex)
    TriggerClientEvent('pvp:forceJoinClient', src, arenaIndex, arena)
    return true
end

function ArenaServerManager.handlePlayerDeath(victim, killerServerId, arenaIndex)
    arenaIndex = arenaIndex or (PlayerManager.players[victim] and PlayerManager.players[victim].arena)
    if not arenaIndex then 
        print("^1[PVP] Pas d'arène trouvée pour la mort du joueur " .. victim .. "^0")
        return 
    end
    
    -- Initialiser le joueur s'il n'existe pas
    if not PlayerManager.players[victim] then
        initializePlayer(victim, arenaIndex)
    end
    
    PlayerManager.players[victim].deaths = PlayerManager.players[victim].deaths + 1
    
    -- Gérer le kill si le tueur est valide
    if killerServerId and killerServerId ~= 0 and PlayerManager.players[killerServerId] then
        PlayerManager.players[killerServerId].kills = PlayerManager.players[killerServerId].kills + 1
        
        -- Notifier le nouveau système HUD
        TriggerClientEvent('pvp:hud:processKill', -1, victim, killerServerId)
        
        print("^2[PVP] Kill: " .. killerServerId .. " -> " .. victim .. "^0")
    else
        print("^3[PVP] Mort sans tueur: " .. victim .. "^0")
    end
    
    -- Respawn dans l'arène
    local arena = getArena(arenaIndex)
    if arena then
        TriggerClientEvent('pvp:respawnInArenaClient', victim, arenaIndex, arena)
    end
end

-- =========================
--  Événements réseau
-- =========================
RegisterNetEvent('pvp:joinArena', function(arenaIndex)
    local src = source
    print("^3[PVP] Demande de rejoindre l'arène " .. arenaIndex .. " par le joueur " .. src .. "^0")
    
    if not arenaIndex or not Config.Arenas[arenaIndex] then
        print("^1[PVP] Index d'arène invalide: " .. tostring(arenaIndex) .. "^0")
        return
    end
    
    local success = ArenaServerManager.joinPlayer(src, arenaIndex)
    if success then
        print("^2[PVP] Joueur " .. src .. " a rejoint l'arène avec succès^0")
    else
        print("^1[PVP] Échec de rejoindre l'arène pour le joueur " .. src .. "^0")
    end
end)

RegisterNetEvent('pvp:playerEnteredArena', function(arenaIndex)
    local src = source
    if not PlayerManager.players[src] then
        initializePlayer(src, arenaIndex)
    end
    print("^2[PVP] Player " .. src .. " entered arena " .. tostring(arenaIndex) .. "^0")
end)

RegisterNetEvent('pvp:playerDied', function(killerServerId, arenaIndex)
    local victim = source
    print("^1[PVP] Joueur " .. victim .. " est mort dans l'arène " .. tostring(arenaIndex) .. "^0")
    ArenaServerManager.handlePlayerDeath(victim, killerServerId, arenaIndex)
end)

-- =========================
--  Commandes serveur
-- =========================
RegisterCommand("checkVMenu", function(source, args, raw)
    local src = source
    if isInArena(src) then
        TriggerClientEvent('vMenu:disableMenu', src, true)
    else
        TriggerClientEvent('vMenu:disableMenu', src, false)
    end
end, false)

-- =========================
--  Gestionnaire de déconnexion
-- =========================
AddEventHandler('playerDropped', function(reason)
    local src = source
    cleanupPlayer(src)
    print("^3[PVP] Player " .. src .. " disconnected and removed from PvP^0")
end)

-- =========================
--  Thread de maintenance optimisé
-- =========================
CreateThread(function()
    while true do
        Wait(10000) -- Vérification toutes les 10 secondes
        
        for src, data in pairs(PlayerManager.players) do
            if isInArena(src) then
                -- Vérifier si le joueur est toujours connecté
                if GetPlayerName(src) then
                    TriggerClientEvent('vMenu:disableMenu', src, true)
                else
                    -- Nettoyer les joueurs déconnectés
                    cleanupPlayer(src)
                end
            end
        end
    end
end)

-- =========================
--  Commandes de debug
-- =========================
RegisterCommand('pvp_stats', function(source)
    local src = source
    local totalPlayers = 0
    for _ in pairs(PlayerManager.players) do
        totalPlayers = totalPlayers + 1
    end
    
    print("^5[PVP DEBUG] Total players tracked: " .. totalPlayers .. "^0")
    for playerId, data in pairs(PlayerManager.players) do
        print("^5[PVP DEBUG] Player " .. playerId .. ": Arena " .. (data.arena or "none") .. 
              ", K/D: " .. data.kills .. "/" .. data.deaths .. "^0")
    end
    
    if src > 0 then
        TriggerClientEvent('chat:addMessage', src, { args = {"PvP Debug", "^5Stats affichées dans la console serveur^0"} })
    end
end, true)

-- =========================
--  Initialisation serveur
-- =========================
CreateThread(function()
    print("^2[PVP] Serveur PVP initialisé avec succès^0")
    print("^2[PVP] " .. #Config.Arenas .. " arènes chargées^0")
    for i, arena in ipairs(Config.Arenas) do
        print("^2[PVP] Arène " .. i .. ": " .. arena.name .. "^0")
    end
end)