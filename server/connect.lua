local server = require 'server.init'


local share = server.share


function server.connect(clientId)
    share.players[clientId] = {}
    local player = share.players[clientId]
    player.x, player.y = 4 * (2 * math.random() - 1), 4 * (2 * math.random() - 1)
end