--[[ FX Information ]]--
fx_version   'cerulean'
use_experimental_fxv2_oal 'yes'
lua54        'yes'
games        { 'rdr3', 'gta5' }
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

--[[ Resource Information ]]--
name         'mv_interactions'
author       ''
version      '0.00.1'
license      'LGPL-3.0-or-later'
repository   ''
description  ''

client_scripts {
	'client/*.lua',
}

server_scripts {
	'client/config.lua',
	'server/*.lua'
}
