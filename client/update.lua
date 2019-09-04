local client = require 'client.init'
local space = require 'client.space'
local selections = require 'client.selections'
local player = require 'client.player'
local camera = require 'client.camera'
local locals = require 'client.locals'
local mode = require 'client.mode'


local share = client.share
local home = client.home


function client.update(dt)
    if not client.connected then
        return
    end

    space.clearWorldSpaceCache()

    selections.clearDeletedSelections()

    locals.nodeManager:processDeletions()
    locals.nodeManager:runThinkRules(dt)

    if home.player then
        player.update(home.player, dt)
    end

    camera.update(dt)

    mode.update(dt)
end