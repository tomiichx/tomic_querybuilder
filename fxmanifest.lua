fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'tomić'
description 'A Laravel-inspired QueryBuilder for FiveM, built on top of ox_lib and oxmysql.'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'src/*.lua',
    'tests/*.lua',
}

files {
    'src/*.lua',
    'tests/*.lua',
}

dependencies {
    'ox_lib',
    'oxmysql'
}
