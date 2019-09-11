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
    graphics_utils.safePushPop(function()
        love.graphics.applyTransform(space.getWorldSpace(node).transform)
        love.graphics.rectangle('line', -0.5 * node.width, -0.5 * node.height, node.width, node.height)
    end)
end

function mode_common.drawNodeOverlays(nodesInDepthOrder)
    local dpiScale = love.graphics.getDPIScale()

    local selecteds = {}

    love.graphics.setLineWidth(1 / math_utils.getScaleFromTransform(camera.getTransform()) / dpiScale)
    love.graphics.setColor(0.8, 0.8, 0.8)
    for _, node in ipairs(nodesInDepthOrder) do
        if selections.primary[node.id] or selections.conflicting[node.id] or selections.secondary[node.id] then
            table.insert(selecteds, node)
        else
            mode_common.drawBoundingBox(node)
        end
    end

    love.graphics.setLineWidth(3 / math_utils.getScaleFromTransform(camera.getTransform()) / dpiScale)
    for _, node in ipairs(selecteds) do
        local r, g, b
        if selections.primary[node.id] then
            r, g, b = 0, 1, 0
        elseif selections.conflicting[node.id] then
            r, g, b = 1, 0, 0
        elseif selections.secondary[node.id] then
            r, g, b = 0.5, 0, 1
        end
        love.graphics.setColor(r, g, b)
        mode_common.drawBoundingBox(node)
    end
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