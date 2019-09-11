local selections = require 'client.selections'
local locals = require 'client.locals'
local graphics_utils = require 'common.graphics_utils'
local space = require 'client.space'
local camera = require 'client.camera'
local math_utils = require 'common.math_utils'


local mode_common = {}


--
-- Draw
--

function mode_common.drawBoundingBox(node)
    love.graphics.rectangle('line', -0.5 * node.width, -0.5 * node.height, node.width, node.height)
end

function mode_common.drawForEachNode(nodeIds, func)
    graphics_utils.safePushPop('all', function()
        love.graphics.setLineWidth(1.5 / math_utils.getScaleFromTransform(camera.getTransform()))
        for id in pairs(nodeIds) do
            local node = locals.nodeManager:getById(id)
            if node then
                graphics_utils.safePushPop('all', function()
                    love.graphics.applyTransform(space.getWorldSpace(node).transform)
                    func(id, node)
                end)
            end
        end
    end)
end

function mode_common.drawSelections()
    love.graphics.setColor(0, 1, 0)
    mode_common.drawForEachNode(selections.primary, function(id, node)
        mode_common.drawBoundingBox(node)
    end)

    love.graphics.setColor(1, 0, 0)
    mode_common.drawForEachNode(selections.conflicting, function(id, node)
        mode_common.drawBoundingBox(node)
    end)

    love.graphics.setColor(0.5, 0, 1)
    mode_common.drawForEachNode(selections.secondary, function(id, node)
        mode_common.drawBoundingBox(node)
    end)
end

function mode_common.drawWorldSpace()
    mode_common.drawSelections()
end


--
-- Mouse
--

function mode_common.getCursorName()
    return 'normal'
end

function mode_common.wheelmoved(x, y)
    if y > 0 then
        camera.zoomIn()
    end
    if y < 0 then
        camera.zoomOut()
    end
end


return mode_common