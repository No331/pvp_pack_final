-- Fichier de compatibilité - redirige vers le nouveau système
exports('isPlayerInArena', function()
    return PlayerData and PlayerData.inArena or false
end)

exports('getPlayerArena', function()
    return PlayerData and PlayerData.currentArena or nil
end)

exports('getPlayerStats', function()
    return PlayerData and PlayerData.hud or { kills = 0, deaths = 0 }
end)