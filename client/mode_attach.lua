local camera = require 'client.camera'
local mode_common = require 'client.mode_common'
local selections = require 'client.selections'
local graphics_utils = require 'common.graphics_utils'
local locals = require 'client.locals'
local space = require 'client.space'
local math_utils = require 'common.math_utils'


local mode_attach = {}


--
-- Update / mouse
--

local dragging = false
local pressedWorldMouseX, pressedWorldMouseY
local currentTarget

function mode_attach.update(dt)
    if dragging then
        local screenMouseX, screenMouseY = love.mouse.getPosition()
        local hits = mode_common.getNodesAt(camera.getTransform():inverseTransformPoint(screenMouseX, screenMouseY))
        currentTarget = nil
        for i = #hits, 1, -1 do
            local hit = hits[i]
            if hit.type == 'group' then
                currentTarget = hit
            end
        end
    end
end

function mode_attach.mousepressed(x, y, button, isTouch, presses)
    if button == 1 then
        pressedWorldMouseX, pressedWorldMouseY = camera.getTransform():inverseTransformPoint(x, y)
        local hits = mode_common.getNodesAt(pressedWorldMouseX, pressedWorldMouseY)
        for _, hit in ipairs(hits) do
            if selections.isSelected(hit.id, 'primary') then
                dragging = true
                break
            end
        end
    end
end

function mode_attach.mousereleased(x, y, button, isTouch, presses)
    if button == 1 then
        if dragging then
            local targetTransform = space.getWorldSpace(currentTarget).transform
            selections.forEach('primary', function(id, node)
                local succeeded, err = pcall(function()
                    locals.nodeManager:setParent(node, currentTarget and currentTarget.id)
                end)
                if succeeded then
                    local transform = space.getWorldSpace(node).transform
                    node.x, node.y = targetTransform:inverseTransformPoint(math_utils.getTranslationFromTransform(transform))
                    node.rotation = math_utils.getRotationFromTransform(transform) - math_utils.getRotationFromTransform(targetTransform)
                else
                    print(err)
                end
            end)

            pressedWorldMouseX, pressedWorldMouseY = nil, nil
            dragging = false
            currentTarget = nil
        end
    end
end


--
-- Draw
--

function mode_attach.getCursorName()
    return 'normal_add'
end

function mode_attach.drawNodeOverlays(nodesInDepthOrder)
    mode_common.drawNodeOverlays(nodesInDepthOrder)

    -- Target
    if currentTarget then
        graphics_utils.safePushPop('all', function()
            love.graphics.setColor(0.7, 0, 0.4)
            mode_common.drawBoundingBox(currentTarget, 5)
        end)
    end

    -- Attachment lines
    graphics_utils.safePushPop('all', function()
        mode_common.setPixelLineWidth(3)
        love.graphics.setColor(0.7, 0.6, 0.9)
        selections.forEach('primary', function(id, node)
            local worldEndX, worldEndY
            if dragging then -- Attachment lines to mouse if dragging
                worldEndX, worldEndY = camera.getTransform():inverseTransformPoint(love.mouse.getPosition())
            elseif node.parentId then -- Attachment lines to parent if not dragging
                local parent = locals.nodeManager:getById(node.parentId)
                if parent then
                    worldEndX, worldEndY = math_utils.getTranslationFromTransform(space.getWorldSpace(parent).transform)
                end
            end
            if worldEndX and worldEndY then
                local worldStartX, worldStartY = math_utils.getTranslationFromTransform(space.getWorldSpace(node).transform)
                love.graphics.line(worldStartX, worldStartY, worldEndX, worldEndY)
            end
        end)
    end)
end


return mode_attach