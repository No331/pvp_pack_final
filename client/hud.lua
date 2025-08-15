-- =========================
--  Gestionnaire HUD Moderne
-- =========================
local HudManager = {
    isVisible = false,
    currentStats = {
        kills = 0,
        deaths = 0,
        assists = 0
    },
    lastDamagers = {}, -- Pour tracker les assists
    damageTimeout = 10000 -- 10 secondes pour compter un assist
}

-- =========================
--  Fonctions utilitaires
-- =========================
local function sendHudMessage(action, data)
    SendNUIMessage({
        action = action,
        kills = data and data.kills or HudManager.currentStats.kills,
        deaths = data and data.deaths or HudManager.currentStats.deaths,
        assists = data and data.assists or HudManager.currentStats.assists,
        arenaName = data and data.arenaName or nil
    })
end

-- =========================
--  Gestion des assists
-- =========================
local function trackDamage(victimId, attackerId)
    if not victimId or not attackerId or victimId == attackerId then return end
    
    local currentTime = GetGameTimer()
    
    -- Initialiser la table pour la victime si nécessaire
    if not HudManager.lastDamagers[victimId] then
        HudManager.lastDamagers[victimId] = {}
    end
    
    -- Enregistrer le dégât
    HudManager.lastDamagers[victimId][attackerId] = currentTime
    
    -- Nettoyer les anciens dégâts (plus de 10 secondes)
    for attacker, timestamp in pairs(HudManager.lastDamagers[victimId]) do
        if currentTime - timestamp > HudManager.damageTimeout then
            HudManager.lastDamagers[victimId][attacker] = nil
        end
    end
end

local function getAssistants(victimId, killerId)
    if not HudManager.lastDamagers[victimId] then return {} end
    
    local assistants = {}
    local currentTime = GetGameTimer()
    
    for attackerId, timestamp in pairs(HudManager.lastDamagers[victimId]) do
        -- Vérifier que ce n'est pas le killer et que le dégât est récent
        if attackerId ~= killerId and (currentTime - timestamp) <= HudManager.damageTimeout then
            table.insert(assistants, attackerId)
        end
    end
    
    -- Nettoyer la table après traitement
    HudManager.lastDamagers[victimId] = nil
    
    return assistants
end

-- =========================
--  Fonctions principales
-- =========================
function HudManager.show(arenaName)
    -- Ne montrer le HUD que si le joueur est dans une arène
    if HudManager.isVisible or not PlayerData or not PlayerData.inArena then return end
    
    HudManager.isVisible = true
    HudManager.currentStats = { kills = 0, deaths = 0, assists = 0 }
    
    sendHudMessage('showHud', { arenaName = arenaName })
    
    print("^2[HUD] HUD affiché pour l'arène: " .. (arenaName or "ARENA") .. "^0")
end

function HudManager.hide()
    if not HudManager.isVisible then return end
    
    HudManager.isVisible = false
    HudManager.currentStats = { kills = 0, deaths = 0, assists = 0 }
    HudManager.lastDamagers = {}
    
    sendHudMessage('hideHud')
    
    print("^3[HUD] HUD masqué^0")
end

function HudManager.updateStats(kills, deaths, assists)
    -- Ne mettre à jour que si en arène et HUD visible
    if not HudManager.isVisible or not PlayerData or not PlayerData.inArena then return end
    
    HudManager.currentStats.kills = kills or 0
    HudManager.currentStats.deaths = deaths or 0
    HudManager.currentStats.assists = assists or 0
    
    sendHudMessage('updateStats', HudManager.currentStats)
end

function HudManager.addKill()
    -- Ne compter les kills que si en arène
    if not HudManager.isVisible or not PlayerData or not PlayerData.inArena then return end
    
    HudManager.currentStats.kills = HudManager.currentStats.kills + 1
    sendHudMessage('updateKill', { kills = HudManager.currentStats.kills })
    
    print("^2[HUD] Kill ajouté: " .. HudManager.currentStats.kills .. "^0")
end

function HudManager.addDeath()
    -- Ne compter les morts que si en arène
    if not HudManager.isVisible or not PlayerData or not PlayerData.inArena then return end
    
    HudManager.currentStats.deaths = HudManager.currentStats.deaths + 1
    sendHudMessage('updateDeath', { deaths = HudManager.currentStats.deaths })
    
    print("^1[HUD] Mort ajoutée: " .. HudManager.currentStats.deaths .. "^0")
end

function HudManager.addAssist()
    -- Ne compter les assists que si en arène
    if not HudManager.isVisible or not PlayerData or not PlayerData.inArena then return end
    
    HudManager.currentStats.assists = HudManager.currentStats.assists + 1
    sendHudMessage('updateAssist', { assists = HudManager.currentStats.assists })
    
    print("^3[HUD] Assist ajoutée: " .. HudManager.currentStats.assists .. "^0")
end

function HudManager.getStats()
    return HudManager.currentStats
end

function HudManager.isHudVisible()
    return HudManager.isVisible
end

-- =========================
--  Thread de détection des dégâts
-- =========================
local function startDamageTracking()
    CreateThread(function()
        while true do
            -- Ne tracker les dégâts que si en arène
            if PlayerData and PlayerData.inArena then
                local playerPed = PlayerPedId()
                local playerId = PlayerId()
                
                -- Vérifier si le joueur a infligé des dégâts
                if HasEntityBeenDamagedByAnyPed(playerPed) then
                    local damager = GetPedSourceOfDeath(playerPed)
                    if damager and damager ~= 0 and damager ~= playerPed then
                        local damagerPlayer = NetworkGetPlayerIndexFromPed(damager)
                        if damagerPlayer and damagerPlayer ~= -1 then
                            local damagerServerId = GetPlayerServerId(damagerPlayer)
                            trackDamage(GetPlayerServerId(playerId), damagerServerId)
                        end
                    end
                    ClearEntityLastDamageEntity(playerPed)
                end
                
                Wait(100) -- Vérification toutes les 100ms quand en arène
            else
                Wait(1000) -- Moins fréquent hors arène
            end
        end
    end)
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

RegisterNetEvent('pvp:hud:updateStats', function(kills, deaths, assists)
    HudManager.updateStats(kills, deaths, assists)
end)

RegisterNetEvent('pvp:hud:addKill', function()
    HudManager.addKill()
end)

RegisterNetEvent('pvp:hud:addDeath', function()
    HudManager.addDeath()
end)

RegisterNetEvent('pvp:hud:addAssist', function()
    HudManager.addAssist()
end)

RegisterNetEvent('pvp:hud:processKill', function(victimId, killerId)
    local playerId = GetPlayerServerId(PlayerId())
    
    -- Si c'est nous qui avons tué
    if killerId == playerId then
        HudManager.addKill()
    -- Si c'est nous qui sommes morts
    elseif victimId == playerId then
        HudManager.addDeath()
    else
        -- Vérifier si on a une assist
        local assistants = getAssistants(victimId, killerId)
        for _, assistantId in ipairs(assistants) do
            if assistantId == playerId then
                HudManager.addAssist()
                break
            end
        end
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
    startDamageTracking()
    print("^2[HUD] Système HUD initialisé^0")
end)