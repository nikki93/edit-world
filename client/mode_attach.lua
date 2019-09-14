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
local currentTarget

function mode_attach.update(dt)
    if dragging then
        -- Watch for applicable targets at mouse position
        local screenMouseX, screenMouseY = love.mouse.getPosition()
        local hits = mode_common.getNodesAt(camera.getTransform():inverseTransformPoint(screenMouseX, screenMouseY))
        currentTarget = nil
        for i = #hits, 1, -1 do
            local hit = hits[i]
            if hit.type == 'group' then
                currentTarget = hit
            end
            if selections.isSelected(hit.id, 'primary') then
                currentTarget = nil
                break
            end
        end
    end
end

function mode_attach.mousepressed(x, y, button, isTouch, presses)
    if button == 1 then
        -- Check if clicked on a selection
        local hits = mode_common.getNodesAt(camera.getTransform():inverseTransformPoint(x, y))
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
            -- Set target as parent, keeping nodes in same world-space transformation
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
            love.graphics.setColor(1, 0, 1)
            mode_common.drawBoundingBox(currentTarget, 2)
        end)
    end

    -- Attachment lines
    graphics_utils.safePushPop('all', function()
        selections.forEach('primary', function(id, node)
            -- Compute end point
            local worldEndX, worldEndY
            if dragging then -- To mouse if dragging
                worldEndX, worldEndY = camera.getTransform():inverseTransformPoint(love.mouse.getPosition())
            elseif node.parentId then -- To parent if not dragging
                local parent = locals.nodeManager:getById(node.parentId)
                if parent then
                    worldEndX, worldEndY = math_utils.getTranslationFromTransform(space.getWorldSpace(parent).transform)
                    love.graphics.setColor(1, 0, 1)
                    mode_common.drawBoundingBox(parent, 2)
                end
            end

            if worldEndX and worldEndY then
                local worldStartX, worldStartY = math_utils.getTranslationFromTransform(space.getWorldSpace(node).transform)
                if dragging then
                    if currentTarget then
                        love.graphics.setColor(1, 0, 1)
                    else -- Different color if detaching
                        love.graphics.setColor(0, 0.4, 0.8)
                    end
                else
                    love.graphics.setColor(1, 0, 1)
                end
                love.graphics.setLineWidth(mode_common.pixelsToWorld(2))
                love.graphics.line(worldStartX, worldStartY, worldEndX, worldEndY)
                if not (dragging and not currentTarget) then -- Don't draw ends if detaching
                    love.graphics.circle('fill', worldStartX, worldStartY, mode_common.pixelsToWorld(6))
                end
            end
        end)
    end)
end


return mode_attach