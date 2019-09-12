local client = require 'client.init'
local space = require 'client.space'
local selections = require 'client.selections'
local player = require 'client.player'
local camera = require 'client.camera'
local locals = require 'client.locals'
local mode = require 'client.mode'
local hud = require 'client.hud'
local rule_constants = require 'common.rule_constants'


local share = client.share
local home = client.home


function client.update(dt)
    if not client.connected then
        return
    end

    local everyFrameParams = { dt = dt }
    locals.nodeManager:forEach(function(id, node)
        if node.type == 'group' then
            locals.nodeManager:getProxy(node):runRules(rule_constants.EVENT_EVERY_FRAME, everyFrameParams)
        end
    end)

    if home.player then
        player.update(home.player, dt)
    end

    camera.update(dt)

    selections.clearDeletedSelections()

    mode.update(dt)
    hud.update(dt)

    space.clearWorldSpaceCache()
end