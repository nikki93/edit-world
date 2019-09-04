local client = require 'client.init'
local graphics_utils = require 'client.graphics_utils'
local camera = require 'client.camera'
local locals = require 'client.locals'
local space = require 'client.space'
local node_types = require 'common.node_types'
local gizmos = require 'client.gizmos'


local share = client.share


local function drawBackground()
    local c = share.settings.backgroundColor
    love.graphics.clear(c.r, c.g, c.b)
end

function client.draw()
    if not client.connected then
        love.graphics.print('connecting...', 20, 20)
        return
    end

    -- Background
    drawBackground()

    -- Camera transform
    graphics_utils.safePushPop('all', function()
        camera.applyTransform()

        -- Nodes
        local order = {}
        locals.nodeMgr:forEach(function(id, node)
            table.insert(order, node)
        end)
        table.sort(order, space.compareDepth)
        for _, node in ipairs(order) do
            node_types[node.type].draw(node, space.getWorldSpace(node).transform)
        end

        -- Gizmos
        gizmos.draw()
    end)
end