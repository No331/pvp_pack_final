-- =========================
--       Variables
-- =========================
local inArena = false
local currentArena = nil
local gunfightPed = nil
local hud = {kills = 0, deaths = 0}
local isDead = false
local spawnCoords = vector3(250.97, -777.16, 30.86) -- Spawn normal
local arenaBlip = nil
local disableVMenu = false

-- =========================
--  Fonctions utilitaires
-- =========================

-- Génère des coordonnées aléatoires dans l'arène
local function getRandomCoordsInArena(arena)
    local angle = math.rad(math.random(0, 360))
    local distance = math.random() * (arena.radius - 2.0)
    local offsetX = math.cos(angle) * distance
    local offsetY = math.sin(angle) * distance
    return vector3(arena.coord.x + offsetX, arena.coord.y + offsetY, arena.coord.z)
end

-- Crée le blip de zone
local function createArenaBlip(arena)
    if arenaBlip then RemoveBlip(arenaBlip) end
    arenaBlip = AddBlipForRadius(arena.coord.x, arena.coord.y, arena.coord.z, arena.radius)
    SetBlipColour(arenaBlip, 1)
    SetBlipAlpha(arenaBlip, 80)
end

-- Supprime le blip de zone
local function removeArenaBlip()
    if arenaBlip then
        RemoveBlip(arenaBlip)
        arenaBlip = nil
    end
end

-- Activer/désactiver spawn auto
local function toggleAutoSpawn(state)
    exports.spawnmanager:setAutoSpawn(state)
    exports.spawnmanager:setAutoSpawnCallback(function() end)
end

-- =========================
--       HUD (Kills / Deaths / KDA)
-- =========================
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if inArena then
            local x, y = 0.015, 0.02 -- Position en haut à gauche
            local scale = 0.35
            local kda = hud.kills
            local deaths = hud.deaths
            local ratio = 0
            if deaths == 0 then
                ratio = hud.kills
            else
                ratio = math.floor((hud.kills / hud.deaths) * 100) / 100
            end

            -- Kills
            SetTextFont(4)
            SetTextScale(scale, scale)
            SetTextColour(255, 255, 255, 255)
            SetTextOutline()
            SetTextEntry("STRING")
            AddTextComponentString("🔫 Kills: " .. hud.kills)
            DrawText(x, y)

            -- Deaths
            SetTextEntry("STRING")
            AddTextComponentString("💀 Morts: " .. hud.deaths)
            DrawText(x, y + 0.03)

            -- KDA
            SetTextEntry("STRING")
            AddTextComponentString("📊 KDA: " .. ratio)
            DrawText(x, y + 0.06)
        end
    end
end)

-- =========================
--  Blocage vMenu / Noclip
-- =========================
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if disableVMenu then
            DisableControlAction(0, 244, true) -- M
            DisableControlAction(0, 288, true) -- F1
            DisableControlAction(0, 170, true) -- F3
            DisableControlAction(0, 166, true) -- F5
            DisableControlAction(0, 167, true) -- F6
            DisableControlAction(0, 289, true) -- F2 Noclip
            TriggerEvent('vMenu:disableMenu', true)
        else
            TriggerEvent('vMenu:disableMenu', false)
        end
    end
end)

-- =========================
--  PNJ entrée arène
-- =========================
Citizen.CreateThread(function()
    local model = GetHashKey(Config.PedModel)
    RequestModel(model)
    local t = GetGameTimer()
    while not HasModelLoaded(model) and (GetGameTimer() - t) < 5000 do Citizen.Wait(10) end
    gunfightPed = CreatePed(4, model, Config.SpawnPoint.x, Config.SpawnPoint.y, Config.SpawnPoint.z, Config.SpawnHeading, false, true)
    FreezeEntityPosition(gunfightPed, true)
    SetEntityInvincible(gunfightPed, true)
    SetBlockingOfNonTemporaryEvents(gunfightPed, true)

    while true do
        Citizen.Wait(0)
        local p = PlayerPedId()
        local pcoords = GetEntityCoords(p)
        local d = #(pcoords - Config.SpawnPoint)

        if d < 50.0 then
            DrawMarker(1, Config.SpawnPoint.x, Config.SpawnPoint.y, Config.SpawnPoint.z - 1.0, 0,0,0, 0,0,0, 1.0,1.0,0.2, 50,200,255, 100, false, true, 2, false, nil, nil, false)
            if d < Config.InteractDistance then
                SetTextComponentFormat('STRING')
                AddTextComponentString('Appuyez sur ~INPUT_CONTEXT~ pour rejoindre une arène PvP')
                DisplayHelpTextFromStringLabel(0,0,1,-1)
                if IsControlJustReleased(0, 38) then
                    TriggerEvent('pvp:openArenaMenu')
                end
            end
        end

        if inArena then
            if currentArena and Config.Arenas and Config.Arenas[currentArena] then
                local a = Config.Arenas[currentArena]
                DrawMarker(1, a.coord.x, a.coord.y, a.coord.z - 1.0, 0,0,0, 0,0,0, a.radius * 2.0, a.radius * 2.0, 1.0, 255, 0, 0, 100, false, true, 2, false, nil, nil, false)
                if #(pcoords - a.coord) > a.radius then
                    SetEntityCoords(p, a.coord.x, a.coord.y, a.coord.z)
                    TriggerEvent('chat:addMessage', { args = {"PvP", "^1Vous ne pouvez pas sortir de la zone !"} })
                end
            end

            if IsControlJustReleased(0, 38) then
                inArena = false
                currentArena = nil
                disableVMenu = false
                RemoveAllPedWeapons(PlayerPedId(), true)
                toggleAutoSpawn(true)
                SetEntityCoords(PlayerPedId(), spawnCoords.x, spawnCoords.y, spawnCoords.z)
                removeArenaBlip()
                TriggerEvent('chat:addMessage', { args = {"PvP", "^2Vous avez quitté le PvP."} })
            end
        end
    end
end)

-- =========================
--  Menu arène
-- =========================
RegisterNetEvent('pvp:openArenaMenu')
AddEventHandler('pvp:openArenaMenu', function()
    SetNuiFocus(true, true)
    SendNUIMessage({ action = "openArenaMenu", arenas = Config.Arenas })
end)

RegisterNUICallback("selectArena", function(data, cb)
    local arenaIndex = tonumber(data.index)
    if arenaIndex and Config.Arenas[arenaIndex] then
        TriggerServerEvent("pvp:joinArena", arenaIndex)
        SetNuiFocus(false, false)
        cb("ok")
    else
        cb("error")
    end
end)

RegisterNUICallback("closeMenu", function(_, cb)
    SetNuiFocus(false, false)
    cb("ok")
end)

-- =========================
--  Entrée arène
-- =========================
RegisterNetEvent('pvp:forceJoinClient')
AddEventHandler('pvp:forceJoinClient', function(arenaIndex, arenaData)
    local a = arenaData
    inArena = true
    currentArena = arenaIndex
    hud.kills = 0
    hud.deaths = 0
    toggleAutoSpawn(false)
    disableVMenu = true

    DoScreenFadeOut(200)
    Citizen.Wait(250)

    local spawnPos = getRandomCoordsInArena(a)
    SetEntityCoords(PlayerPedId(), spawnPos.x, spawnPos.y, spawnPos.z, false, false, false, true)
    SetEntityHeading(PlayerPedId(), a.heading or 0.0)
    Citizen.Wait(200)
    DoScreenFadeIn(200)

    GiveWeaponToPed(PlayerPedId(), GetHashKey(Config.GunWeapon), 250, false, true)
    SetPedAmmo(PlayerPedId(), GetHashKey(Config.GunWeapon), 250)

    createArenaBlip(a)
    TriggerServerEvent('pvp:playerEnteredArena', arenaIndex)
    TriggerEvent('chat:addMessage', { args = {"PvP", "^2Vous avez rejoint l'arène " .. a.name .. " !"} })
end)

-- =========================
--  Quitter PvP
-- =========================
RegisterCommand("quitpvp", function()
    if inArena then
        inArena = false
        currentArena = nil
        disableVMenu = false
        RemoveAllPedWeapons(PlayerPedId(), true)
        toggleAutoSpawn(true)
        SetEntityCoords(PlayerPedId(), spawnCoords.x, spawnCoords.y, spawnCoords.z)
        removeArenaBlip()
        TriggerEvent('chat:addMessage', { args = {"PvP", "^2Vous avez quitté le PvP."} })
    else
        TriggerEvent('chat:addMessage', { args = {"PvP", "^1Vous n'êtes pas en PvP."} })
    end
end)

-- =========================
--  Gestion morts / respawn
-- =========================
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(200)
        local ped = PlayerPedId()
        if not isDead and IsEntityDead(ped) then
            isDead = true
            local killer = GetPedSourceOfDeath(ped)
            local killerServerId = nil
            if killer and killer ~= 0 then
                local killerPlayer = NetworkGetPlayerIndexFromPed(killer)
                if killerPlayer and killerPlayer ~= -1 then
                    killerServerId = GetPlayerServerId(killerPlayer)
                end
            end
            TriggerServerEvent('pvp:playerDied', killerServerId, currentArena)
        elseif isDead and not IsEntityDead(ped) then
            isDead = false
        end
    end
end)

RegisterNetEvent('pvp:respawnInArenaClient')
AddEventHandler('pvp:respawnInArenaClient', function(arenaIndex, arenaData)
    local a = arenaData
    Citizen.Wait(Config.RespawnDelay)
    local ped = PlayerPedId()
    isDead = false

    local spawnPos = getRandomCoordsInArena(a)
    SetEntityCoords(ped, spawnPos.x, spawnPos.y, spawnPos.z, false, false, false, true)
    SetEntityHeading(ped, a.heading or 0.0)

    NetworkResurrectLocalPlayer(spawnPos.x, spawnPos.y, spawnPos.z, a.heading or 0.0, true, false)
    ClearPedBloodDamage(ped)
    ResetPedVisibleDamage(ped)
    ClearPedLastDamageBone(ped)
    SetEntityHealth(ped, GetEntityMaxHealth(ped))

    GiveWeaponToPed(ped, GetHashKey(Config.GunWeapon), 250, false, true)
    SetPedAmmo(ped, GetHashKey(Config.GunWeapon), 250)
end)

-- =========================
--  Mise à jour HUD
-- =========================
RegisterNetEvent('pvp:updateHud')
AddEventHandler('pvp:updateHud', function(kills, deaths)
    hud.kills = kills
    hud.deaths = deaths
end)

-- =========================
--  Blocage noclip
-- =========================
RegisterCommand("noclip", function()
    if disableVMenu then
        TriggerEvent('chat:addMessage', { args = {"PvP", "^1Le noclip est désactivé en arène !"} })
    end
end, false)
