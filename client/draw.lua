local client = require 'client.init'
local graphics_utils = require 'client.graphics_utils'
local camera = require 'client.camera'
local locals = require 'client.locals'
local space = require 'client.space'
local node_types = require 'common.node_types'
local gizmos = require 'client.gizmos'
local player = require 'client.player'


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
        camera.applyTransform()

        -- Nodes
        local order = {}
        locals.nodeManager:forEach(function(id, node)
            table.insert(order, node)
        end)
        table.sort(order, space.compareDepth)
        for _, node in ipairs(order) do
            node_types[node.type].draw(node, space.getWorldSpace(node).transform)
        end

        -- Gizmos
        gizmos.draw()

        -- Players
        for clientId, p in pairs(share.players) do
            if client.id == clientId and home.player then
                p = home.player
            end
            player.draw(p)
        end
    end)

    -- FPS
    love.graphics.setColor(0, 0, 0)
    love.graphics.print('fps: ' .. love.timer.getFPS(), 20, 20)
end