local server = require 'server.init'


local share = server.share


function server.connect(clientId)
    share.players[clientId] = {}
    local player = share.players[clientId]
    player.x, player.y = math.random(-4, 4), math.random(-4, 4)
end