fx_version 'cerulean'
games { 'gta5' }

author 'ChatGPT'
description 'PvP pack'
version '2.0.0'

-- Scripts
shared_script 'config.lua'

client_scripts {
    'client/main.lua',
    'client.lua' -- Compatibilité
}

server_scripts {
    'server/main.lua',
    'server.lua' -- Compatibilité
}

-- Interface utilisateur
ui_page 'html/index.html'
files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'html/img/*.png',
}

-- Optimisations
lua54 'yes'
use_experimental_fxv2_oal 'yes'
