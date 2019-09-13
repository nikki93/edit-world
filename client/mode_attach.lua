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

local worldMouseX, worldMouseY
local dragging = false
local pressedWorldMouseX, pressedWorldMouseY
local currentTarget

function mode_attach.update(dt)
    if dragging then
        local screenMouseX, screenMouseY = love.mouse.getPosition()
        worldMouseX, worldMouseY = camera.getTransform():inverseTransformPoint(screenMouseX, screenMouseY)
        local hits = mode_common.getNodesAt(worldMouseX, worldMouseY)
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
                local transform = space.getWorldSpace(node).transform
                node.x, node.y = targetTransform:inverseTransformPoint(math_utils.getTranslationFromTransform(transform))
                node.rotation = math_utils.getRotationFromTransform(transform) - math_utils.getRotationFromTransform(targetTransform)
                locals.nodeManager:setParent(node, currentTarget and currentTarget.id)
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
    if dragging then
        graphics_utils.safePushPop('all', function()
            love.graphics.setColor(0.8, 0.8, 0.8)
            for _, node in ipairs(nodesInDepthOrder) do
                if node.type == 'group' then
                    mode_common.drawBoundingBox(node, 1)
                end
            end
        end)

        if currentTarget then
            graphics_utils.safePushPop('all', function()
                love.graphics.setColor(0.7, 0, 0.4)

                mode_common.drawBoundingBox(currentTarget, 5)

                mode_common.setPixelLineWidth(3)
                selections.forEach('primary', function(id, node)
                    local worldX, worldY = math_utils.getTranslationFromTransform(space.getWorldSpace(node).transform)
                    local worldTargetX, worldTargetY = math_utils.getTranslationFromTransform(space.getWorldSpace(currentTarget).transform)
                    love.graphics.line(worldX, worldY, worldTargetX, worldTargetY)
                end)
            end)
        end

        graphics_utils.safePushPop('all', function()
            love.graphics.setColor(1, 0, 1)
            love.graphics.translate(worldMouseX - pressedWorldMouseX, worldMouseY - pressedWorldMouseY)
            selections.forEach('primary', function(id, node)
                mode_common.drawBoundingBox(node, 3)
            end)
        end)
    else
        mode_common.drawNodeOverlays(nodesInDepthOrder)

        graphics_utils.safePushPop('all', function()
            love.graphics.setColor(0.7, 0.6, 0.9)
            mode_common.setPixelLineWidth(3)
            selections.forEach('primary', function(id, node)
                if node.parentId then
                    local parent = locals.nodeManager:getById(node.parentId)
                    if parent then
                        local worldX, worldY = math_utils.getTranslationFromTransform(space.getWorldSpace(node).transform)
                        local worldParentX, worldParentY = math_utils.getTranslationFromTransform(space.getWorldSpace(parent).transform)
                        love.graphics.line(worldX, worldY, worldParentX, worldParentY)
                    end
                end
            end)
        end)
    end
end


return mode_attach