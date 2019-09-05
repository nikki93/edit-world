local client = require 'client.init'
local graphics_utils = require 'client.graphics_utils'
local camera = require 'client.camera'
local locals = require 'client.locals'
local space = require 'client.space'
local node_types = require 'common.node_types'
local player = require 'client.player'
local mode = require 'client.mode'
local hud = require 'client.hud'


local share = client.share
local home = client.home


local function drawBackground()
    local c = share.settings.backgroundColor
    love.graphics.clear(c.r, c.g, c.b)
end

function client.draw()
    -- Connecting / loading?
    if not client.connected then
        love.graphics.print('connecting...', 20, 20)
        return
    end
    if not locals.loaded then
        love.graphics.print('loading...', 20, 20)
        return
    end

    -- Background
    drawBackground()

    -- Camera transform
    graphics_utils.safePushPop('all', function()
        love.graphics.applyTransform(camera.getTransform())

        -- Nodes
        graphics_utils.safePushPop('all', function()
            local order = {}
            locals.nodeManager:forEach(function(id, node)
                table.insert(order, node)
            end)
            table.sort(order, space.compareDepth)
            for _, node in ipairs(order) do
                locals.nodeManager:getProxy(node):draw(space.getWorldSpace(node).transform)
            end
        end)

        -- Mode (world-space)
        graphics_utils.safePushPop('all', function()
            mode.drawWorldSpace()
        end)

        -- Players
        graphics_utils.safePushPop('all', function()
            for clientId, p in pairs(share.players) do
                if client.id == clientId and home.player then
                    p = home.player
                end
                player.draw(p)
            end
        end)
    end)

    -- Mode (screen-space)
    graphics_utils.safePushPop('all', function()
        mode.drawScreenSpace()
    end)

    -- HUD
    hud.draw()

    -- Debug HUD
    graphics_utils.safePushPop('all', function()
        love.graphics.setColor(0, 0, 0)
        love.graphics.print('fps: ' .. love.timer.getFPS(), 20, 20)
        local zoomFactor = camera.getZoomFactor()
        if zoomFactor < 1 then
            love.graphics.print('\nzoom in: ' .. (1 / zoomFactor) .. 'x', 20, 20)
        end
        if zoomFactor > 1 then
            love.graphics.print('\nzoom out: ' .. zoomFactor .. 'x', 20, 20)
        end
    end)
end