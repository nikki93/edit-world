local server = require 'server.init'
local locals = require 'server.locals'
local rule_constants = require 'common.rule_constants'


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
        if node.type == 'group' then
            locals.nodeManager:getProxy(node):runRules(rule_constants.EVENT_EVERY_FRAME, everyFrameParams)
        end
    end)
end