local lib = require 'common.lib'


local client = lib.cs.client

if USE_CASTLE_CONFIG then
    client.useCastleConfig()
else
    client.enabled = true
    client.start('192.168.1.9:22122')
end


return client