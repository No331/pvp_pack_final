-- Fichier de compatibilité - redirige vers le nouveau système
exports('getPlayerArena', function(playerId)
    return PlayerManager.players[playerId] and PlayerManager.players[playerId].arena or nil
end)

exports('getPlayerStats', function(playerId)
    local player = PlayerManager.players[playerId]
    return player and { kills = player.kills, deaths = player.deaths } or { kills = 0, deaths = 0 }
end)

exports('isPlayerInArena', function(playerId)
    return PlayerManager.players[playerId] and PlayerManager.players[playerId].arena ~= nil
end)