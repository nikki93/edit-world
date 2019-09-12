local server = require 'server.init'
local locals = require 'server.locals'


local share = server.share
local homes = server.homes


function server.update(dt)
    for clientId in pairs(share.players) do
        local home = homes[clientId]
        if home and home.player then
            share.players[clientId] = home.player
        end
    end

    local everyFrameParams = { dt = dt }
    locals.nodeManager:forEach(function(id, node)
        locals.nodeManager:getProxy(node):runRules('every frame', everyFrameParams)
    end)
end