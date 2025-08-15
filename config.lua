Config = {}

-- Spawn du PNJ 'GUNFIGHT' et point d'interaction
Config.SpawnPoint = vector3(254.32, -773.16, 30.91)
Config.SpawnHeading = 160.0
Config.PedModel = "csb_dax"  -- Modèle du PNJ
Config.PedName = "GUNFIGHT"
Config.InteractDistance = 2.0           -- Distance pour interagir avec le PNJ

-- Armes et respawn
Config.GunWeapon = "WEAPON_PISTOL"
Config.RespawnDelay = 1500              -- Délai avant respawn en ms

-- Arènes PvP
Config.Arenas = {
    {
        name = "Dock",
        coord = vector3(1021.45, -3278.1, 5.89),
        radius = 40.0,
        heading = 90.0,
    },
    {
        name = "Port",
        coord = vector3(238.36,-2995.33,5.71),
        radius = 40.0,
        heading = 90.0,
    },
    {
        name = "Hangar",
        coord = vector3(36.27, -2711.33, 5.37),
        radius = 40.0,
        heading = 90.0,
    },
    {
        name = "Usine",
        coord = vector3(2764.12, 1524.31, 24.5),
        radius = 40.0,
        heading = 90.0,
    },
}