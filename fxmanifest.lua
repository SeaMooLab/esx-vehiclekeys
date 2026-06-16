fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Kakarot; ESX port by OpenAI'
description 'ESX Legacy port of qb-vehiclekeys: vehicle doors, keys, lockpicks, hotwiring, and carjacking'
version '1.5.0-esx.1'

shared_scripts {
    'locales/en.lua',
    'config.lua',
}

client_script 'client.lua'
server_script 'server.lua'

ui_page 'NUI/index.html'

files {
    'NUI/index.html',
    'NUI/style.css',
    'NUI/script.js',
}

dependency 'es_extended'
