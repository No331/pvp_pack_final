-- =========================
--       Variables globales
-- =========================
PlayerData = {
    inArena = false,
    currentArena = nil,
    isDead = false,
    hud = { kills = 0, deaths = 0 },
    disableVMenu = false
}

local GameObjects = {
    gunfightPed = nil,
    arenaBlip = nil
}

local Constants = {
    SPAWN_COORDS = vector3(250.97, -777.16, 30.86),
    HUD_POSITION = { x = 0.015, y = 0.02 },
    HUD_SCALE = 0.35
}

-- =========================
--  Utilitaires optimisés
-- =========================
local Utils = {}

function Utils.getRandomCoordsInArena(arena)
    local angle = math.rad(math.random(0, 360))
    local distance = math.random() * (arena.radius - 2.0)
    local offsetX = math.cos(angle) * distance
    local offsetY = math.sin(angle) * distance
    return vector3(arena.coord.x + offsetX, arena.coord.y + offsetY, arena.coord.z)
end

function Utils.createArenaBlip(arena)
    if GameObjects.arenaBlip then 
        RemoveBlip(GameObjects.arenaBlip) 
    end
    GameObjects.arenaBlip = AddBlipForRadius(arena.coord.x, arena.coord.y, arena.coord.z, arena.radius)
    SetBlipColour(GameObjects.arenaBlip, 1)
    SetBlipAlpha(GameObjects.arenaBlip, 80)
end

function Utils.removeArenaBlip()
    if GameObjects.arenaBlip then
        RemoveBlip(GameObjects.arenaBlip)
        GameObjects.arenaBlip = nil
    end
end

function Utils.toggleAutoSpawn(state)
    if exports.spawnmanager then
        exports.spawnmanager:setAutoSpawn(state)
        exports.spawnmanager:setAutoSpawnCallback(function() end)
    end
end

-- =========================
--  Gestionnaire vMenu optimisé
-- =========================
local VMenuManager = {}
local vMenuBlocked = false

function VMenuManager.enable()
    if vMenuBlocked then return end
    vMenuBlocked = true
    
    CreateThread(function()
        while vMenuBlocked and PlayerData.disableVMenu do
            DisableControlAction(0, 244, true) -- M
            DisableControlAction(0, 288, true) -- F1
            DisableControlAction(0, 170, true) -- F3
            DisableControlAction(0, 166, true) -- F5
            DisableControlAction(0, 167, true) -- F6
            DisableControlAction(0, 289, true) -- F2 Noclip
            if GetResourceState('vMenu') == 'started' then
                TriggerEvent('vMenu:disableMenu', true)
            end
            Wait(0)
        end
    end)
end

function VMenuManager.disable()
    vMenuBlocked = false
    PlayerData.disableVMenu = false
    if GetResourceState('vMenu') == 'started' then
        TriggerEvent('vMenu:disableMenu', false)
    end
end

-- =========================
--  Gestionnaire PNJ optimisé
-- =========================
local PedManager = {}
local pedThread = false

function PedManager.init()
    CreateThread(function()
        local model = GetHashKey(Config.PedModel)
        RequestModel(model)
        
        local timeout = GetGameTimer() + 5000
        while not HasModelLoaded(model) and GetGameTimer() < timeout do 
            Wait(10) 
        end
        
        if HasModelLoaded(model) then
            GameObjects.gunfightPed = CreatePed(4, model, Config.SpawnPoint.x, Config.SpawnPoint.y, Config.SpawnPoint.z, Config.SpawnHeading, false, true)
            FreezeEntityPosition(GameObjects.gunfightPed, true)
            SetEntityInvincible(GameObjects.gunfightPed, true)
            SetBlockingOfNonTemporaryEvents(GameObjects.gunfightPed, true)
            PedManager.startInteractionThread()
            print("^2[PVP] PNJ créé avec succès^0")
        else
            print("^1[PVP] Erreur: Impossible de charger le modèle du PNJ^0")
        end
    end)
end

function PedManager.startInteractionThread()
    if pedThread then return end
    pedThread = true
    
    CreateThread(function()
        local lastDistance = 999.0
        
        while pedThread do
            local playerPed = PlayerPedId()
            local coords = GetEntityCoords(playerPed)
            local distance = #(coords - Config.SpawnPoint)
            
            -- Optimisation: ne traiter que si la distance a changé significativement
            if math.abs(distance - lastDistance) > 1.0 then
                lastDistance = distance
                
                if distance < 50.0 then
                    if not PlayerData.inArena then
                        DrawMarker(1, Config.SpawnPoint.x, Config.SpawnPoint.y, Config.SpawnPoint.z - 1.0, 
                                 0,0,0, 0,0,0, 1.0,1.0,0.2, 50,200,255, 100, false, true, 2, false, nil, nil, false)
                        
                        if distance < Config.InteractDistance then
                            SetTextComponentFormat('STRING')
                            AddTextComponentString('Appuyez sur ~INPUT_CONTEXT~ pour rejoindre une arène PvP')
                            DisplayHelpTextFromStringLabel(0,0,1,-1)
                            
                            if IsControlJustReleased(0, 38) then
                                print("^3[PVP] Ouverture du menu arène^0")
                                TriggerEvent('pvp:openArenaMenu')
                            end
                        end
                    end
                end
            end
            
            Wait(PlayerData.inArena and 500 or 100) -- Moins fréquent si en arène
        end
    end)
end

-- =========================
--  Gestionnaire Arène optimisé
-- =========================
local ArenaManager = {}
local arenaThread = false

function ArenaManager.startBoundaryCheck()
    if arenaThread or not PlayerData.inArena then return end
    arenaThread = true
    
    CreateThread(function()
        while arenaThread and PlayerData.inArena and PlayerData.currentArena do
            local arena = Config.Arenas[PlayerData.currentArena]
            if not arena then break end
            
            local playerPed = PlayerPedId()
            local coords = GetEntityCoords(playerPed)
            local distance = #(coords - arena.coord)
            
            -- Vérification des limites moins fréquente
            if distance > arena.radius then
                SetEntityCoords(playerPed, arena.coord.x, arena.coord.y, arena.coord.z)
                TriggerEvent('chat:addMessage', { args = {"PvP", "^1Vous ne pouvez pas sortir de la zone !"} })
            end
            
            -- Afficher les instructions de sortie
            SetTextComponentFormat('STRING')
            AddTextComponentString('Appuyez sur ~INPUT_CONTEXT~ pour quitter l\'arène')
            DisplayHelpTextFromStringLabel(0,0,1,-1)
            
            -- Vérification de sortie
            if IsControlJustReleased(0, 38) then
                ArenaManager.leave()
                break
            end
            
            Wait(200) -- Vérification moins fréquente
        end
        arenaThread = false
    end)
end

function ArenaManager.join(arenaIndex, arenaData)
    print("^2[PVP] Rejoindre arène " .. arenaIndex .. " - " .. arenaData.name .. "^0")
    
    PlayerData.inArena = true
    PlayerData.currentArena = arenaIndex
    PlayerData.disableVMenu = true
    
    -- Afficher le HUD
    TriggerEvent('pvp:hud:show', arenaData.name)
    VMenuManager.enable()
    Utils.toggleAutoSpawn(false)
    
    DoScreenFadeOut(200)
    Wait(250)
    
    local spawnPos = Utils.getRandomCoordsInArena(arenaData)
    SetEntityCoords(PlayerPedId(), spawnPos.x, spawnPos.y, spawnPos.z, false, false, false, true)
    SetEntityHeading(PlayerPedId(), arenaData.heading or 0.0)
    
    Wait(200)
    DoScreenFadeIn(200)
    
    GiveWeaponToPed(PlayerPedId(), GetHashKey(Config.GunWeapon), 250, false, true)
    SetPedAmmo(PlayerPedId(), GetHashKey(Config.GunWeapon), 250)
    
    Utils.createArenaBlip(arenaData)
    ArenaManager.startBoundaryCheck()
    
    TriggerServerEvent('pvp:playerEnteredArena', arenaIndex)
    TriggerEvent('chat:addMessage', { args = {"PvP", "^2Vous avez rejoint l'arène " .. arenaData.name .. " !"} })
    
    print("^2[PVP] Arène rejointe avec succès^0")
end

function ArenaManager.leave()
    print("^3[PVP] Quitter l'arène^0")
    
    -- Cacher le HUD AVANT de changer le statut
    TriggerEvent('pvp:hud:hide')
    
    PlayerData.inArena = false
    PlayerData.currentArena = nil
    arenaThread = false
    
    VMenuManager.disable()
    
    RemoveAllPedWeapons(PlayerPedId(), true)
    Utils.toggleAutoSpawn(true)
    SetEntityCoords(PlayerPedId(), Constants.SPAWN_COORDS.x, Constants.SPAWN_COORDS.y, Constants.SPAWN_COORDS.z)
    Utils.removeArenaBlip()
    
    TriggerEvent('chat:addMessage', { args = {"PvP", "^2Vous avez quitté le PvP."} })
end

function ArenaManager.respawn(arenaIndex, arenaData)
    Wait(Config.RespawnDelay)
    
    local ped = PlayerPedId()
    PlayerData.isDead = false
    
    local spawnPos = Utils.getRandomCoordsInArena(arenaData)
    SetEntityCoords(ped, spawnPos.x, spawnPos.y, spawnPos.z, false, false, false, true)
    SetEntityHeading(ped, arenaData.heading or 0.0)
    
    NetworkResurrectLocalPlayer(spawnPos.x, spawnPos.y, spawnPos.z, arenaData.heading or 0.0, true, false)
    ClearPedBloodDamage(ped)
    ResetPedVisibleDamage(ped)
    ClearPedLastDamageBone(ped)
    SetEntityHealth(ped, GetEntityMaxHealth(ped))
    
    GiveWeaponToPed(ped, GetHashKey(Config.GunWeapon), 250, false, true)
    SetPedAmmo(ped, GetHashKey(Config.GunWeapon), 250)
end

-- =========================
--  Gestionnaire de mort optimisé
-- =========================
local DeathManager = {}

function DeathManager.init()
    CreateThread(function()
        while true do
            local ped = PlayerPedId()
            local currentlyDead = IsEntityDead(ped)
            
            if not PlayerData.isDead and currentlyDead then
                PlayerData.isDead = true
                
                if PlayerData.inArena then
                    local killer = GetPedSourceOfDeath(ped)
                    local killerServerId = nil
                    
                    if killer and killer ~= 0 then
                        local killerPlayer = NetworkGetPlayerIndexFromPed(killer)
                        if killerPlayer and killerPlayer ~= -1 then
                            killerServerId = GetPlayerServerId(killerPlayer)
                        end
                    end
                    
                    TriggerServerEvent('pvp:playerDied', killerServerId, PlayerData.currentArena)
                end
            elseif PlayerData.isDead and not currentlyDead then
                PlayerData.isDead = false
            end
            
            Wait(500) -- Vérification moins fréquente
        end
    end)
end

-- =========================
--  Événements réseau
-- =========================
RegisterNetEvent('pvp:openArenaMenu', function()
    print("^3[PVP] Événement openArenaMenu reçu^0")
    SetNuiFocus(true, true)
    SendNUIMessage({ 
        action = "openArenaMenu", 
        arenas = Config.Arenas 
    })
end)

RegisterNetEvent('pvp:forceJoinClient', function(arenaIndex, arenaData)
    print("^2[PVP] Événement forceJoinClient reçu - Index: " .. arenaIndex .. "^0")
    ArenaManager.join(arenaIndex, arenaData)
end)

RegisterNetEvent('pvp:respawnInArenaClient', function(arenaIndex, arenaData)
    ArenaManager.respawn(arenaIndex, arenaData)
end)

-- =========================
--  Callbacks NUI
-- =========================
RegisterNUICallback("selectArena", function(data, cb)
    local arenaIndex = tonumber(data.index)
    print("^3[PVP] Callback selectArena - Index: " .. tostring(arenaIndex) .. "^0")
    
    if arenaIndex and Config.Arenas[arenaIndex] then
        print("^2[PVP] Arène valide trouvée, envoi au serveur^0")
        TriggerServerEvent("pvp:joinArena", arenaIndex)
        SetNuiFocus(false, false)
        cb("ok")
    else
        print("^1[PVP] Arène invalide - Index: " .. tostring(arenaIndex) .. "^0")
        cb("error")
    end
end)

RegisterNUICallback("closeMenu", function(_, cb)
    print("^3[PVP] Callback closeMenu^0")
    SetNuiFocus(false, false)
    cb("ok")
end)

-- =========================
--  Commandes
-- =========================
RegisterCommand("quitpvp", function()
    if PlayerData.inArena then
        ArenaManager.leave()
    else
        TriggerEvent('chat:addMessage', { args = {"PvP", "^1Vous n'êtes pas en PvP."} })
    end
end)

RegisterCommand("noclip", function()
    if PlayerData.disableVMenu then
        TriggerEvent('chat:addMessage', { args = {"PvP", "^1Le noclip est désactivé en arène !"} })
    end
end, false)

-- Commande de debug
RegisterCommand("pvp_debug", function()
    print("^5[PVP DEBUG]^0")
    print("  - inArena: " .. tostring(PlayerData.inArena))
    print("  - currentArena: " .. tostring(PlayerData.currentArena))
    print("  - isDead: " .. tostring(PlayerData.isDead))
    print("  - PNJ existe: " .. tostring(GameObjects.gunfightPed ~= nil))
    print("  - Thread PNJ: " .. tostring(pedThread))
    print("  - Thread arène: " .. tostring(arenaThread))
end, false)

-- =========================
--  Initialisation
-- =========================
CreateThread(function()
    Wait(1000) -- Attendre que tout soit chargé
    PedManager.init()
    DeathManager.init()
    print("^2[PVP] Client initialisé avec succès^0")
end)