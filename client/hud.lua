-- =========================
--  Gestionnaire HUD Moderne
-- =========================
local HudManager = {
    isVisible = false,
    currentStats = {
        kills = 0,
        deaths = 0
    }
}

-- =========================
--  Fonctions utilitaires
-- =========================
local function sendHudMessage(action, data)
    SendNUIMessage({
        action = action,
        kills = data and data.kills or HudManager.currentStats.kills,
        deaths = data and data.deaths or HudManager.currentStats.deaths,
        arenaName = data and data.arenaName or nil
    })
end

-- =========================
--  Fonctions principales
-- =========================
function HudManager.show(arenaName)
    if HudManager.isVisible or not PlayerData or not PlayerData.inArena then return end
    
    HudManager.isVisible = true
    HudManager.currentStats = { kills = 0, deaths = 0 }
    
    sendHudMessage('showHud', { arenaName = arenaName })
    
    print("^2[HUD] HUD affiché pour l'arène: " .. (arenaName or "ARENA") .. "^0")
end

function HudManager.hide()
    if not HudManager.isVisible then return end
    
    HudManager.isVisible = false
    HudManager.currentStats = { kills = 0, deaths = 0 }
    
    sendHudMessage('hideHud')
    
    print("^3[HUD] HUD masqué^0")
end

function HudManager.updateStats(kills, deaths)
    if not HudManager.isVisible or not PlayerData or not PlayerData.inArena then return end
    
    HudManager.currentStats.kills = kills or 0
    HudManager.currentStats.deaths = deaths or 0
    
    sendHudMessage('updateStats', HudManager.currentStats)
end

function HudManager.addKill()
    if not HudManager.isVisible or not PlayerData or not PlayerData.inArena then return end
    
    HudManager.currentStats.kills = HudManager.currentStats.kills + 1
    sendHudMessage('updateKill', { kills = HudManager.currentStats.kills })
    
    print("^2[HUD] Kill ajouté: " .. HudManager.currentStats.kills .. "^0")
end

function HudManager.addDeath()
    if not HudManager.isVisible or not PlayerData or not PlayerData.inArena then return end
    
    HudManager.currentStats.deaths = HudManager.currentStats.deaths + 1
    sendHudMessage('updateDeath', { deaths = HudManager.currentStats.deaths })
    
    print("^1[HUD] Mort ajoutée: " .. HudManager.currentStats.deaths .. "^0")
end

function HudManager.getStats()
    return HudManager.currentStats
end

function HudManager.isHudVisible()
    return HudManager.isVisible
end

-- =========================
--  Événements
-- =========================
RegisterNetEvent('pvp:hud:show', function(arenaName)
    HudManager.show(arenaName)
end)

RegisterNetEvent('pvp:hud:hide', function()
    HudManager.hide()
end)

RegisterNetEvent('pvp:hud:updateStats', function(kills, deaths)
    HudManager.updateStats(kills, deaths)
end)

RegisterNetEvent('pvp:hud:addKill', function()
    HudManager.addKill()
end)

RegisterNetEvent('pvp:hud:addDeath', function()
    HudManager.addDeath()
end)

RegisterNetEvent('pvp:hud:processKill', function(victimId, killerId)
    local playerId = GetPlayerServerId(PlayerId())
    
    -- Si c'est nous qui avons tué
    if killerId == playerId then
        HudManager.addKill()
    -- Si c'est nous qui sommes morts
    elseif victimId == playerId then
        HudManager.addDeath()
    end
end)

-- =========================
--  Exports
-- =========================
exports('getHudStats', function()
    return HudManager.getStats()
end)

exports('isHudVisible', function()
    return HudManager.isHudVisible()
end)

exports('showHud', function(arenaName)
    HudManager.show(arenaName)
end)

exports('hideHud', function()
    HudManager.hide()
end)

-- =========================
--  Initialisation
-- =========================
CreateThread(function()
    print("^2[HUD] Système HUD initialisé^0")
end)