local client = require 'client.init'
local space = require 'client.space'
local selections = require 'client.selections'
local player = require 'client.player'
local camera = require 'client.camera'
local locals = require 'client.locals'
local mode = require 'client.mode'
local hud = require 'client.hud'


local share = client.share
local home = client.home


local prevDPIScale = love.graphics.getDPIScale()

function client.update(dt)
    local currDPIScale = love.graphics.getDPIScale()
    if prevDPIScale ~= currDPIScale then
        network.async(function()
            hud.reloadFonts()
        end)
        prevDPIScale = currDPIScale
    end

    if not client.connected then
        return
    end

    locals.nodeManager:runThinkRules(dt)

    if home.player then
        player.update(home.player, dt)
    end

    camera.update(dt)

    selections.clearDeletedSelections()

    mode.update(dt)

    space.clearWorldSpaceCache()
end