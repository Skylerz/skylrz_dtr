resource_manifest_version '44febabe-d386-4d18-afbe-5e627f4af937'

description 'A flexible dtr for whitelisted jobs. The aim for this plugin/resource is to track how a player is active on his/her whitelistedjob. by SKYLRZ'

version '2.0.0'

client_script 'client/main.lua'

server_scripts {

  '@mysql-async/lib/MySQL.lua',
  'server/main.lua'

}
