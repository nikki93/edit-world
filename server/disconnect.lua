local server = require 'server.init'


local share = server.share


function server.disconnect(clientId)
    share.players[clientId] = nil
end