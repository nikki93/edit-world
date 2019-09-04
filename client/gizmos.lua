local selections = require 'client.selections'
local locals = require 'client.locals'
local graphics_utils = require 'client.graphics_utils'
local space = require 'client.space'


local gizmos = {}


local function drawGizmosWithColor(nodeIds, r, g, b)
    graphics_utils.safePushPop('all', function()
        love.graphics.setColor(r, g, b)
        for id in pairs(nodeIds) do
            local node = locals.nodeManager:getById(id)
            if node then
                love.graphics.applyTransform(space.getWorldSpace(node).transform)
                love.graphics.rectangle('line', -0.5 * node.width, -0.5 * node.height, node.width, node.height)
            end
        end
    end)
end

function gizmos.draw()
    drawGizmosWithColor(selections.primary, 0, 1, 0)
    drawGizmosWithColor(selections.secondary, 1, 0, 0)
end


return gizmos