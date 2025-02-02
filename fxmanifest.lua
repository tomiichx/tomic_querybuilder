fx_version 'cerulean'
game 'common'
use_experimental_fxv2_oal 'yes'
lua54 'yes'

author 'tomić'
description 'A Laravel-inspired QueryBuilder for FiveM, built on top of ox_lib and oxmysql.'
version '1.0.0'

environment 'production'

server_only 'yes'

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    '@ox_lib/init.lua',
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
