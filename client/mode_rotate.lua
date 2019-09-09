local selections = require 'client.selections'
local space = require 'client.space'
local camera = require 'client.camera'
local ui = castle.ui


local mode_rotate = {}


local nSelections
local worldPivotX, worldPivotY = 0, 0

local snapToIncrement = true
local incrementDegrees = 45


--
-- Update
--

function mode_rotate.update(dt)
    nSelections = selections.numSelections('primary')

    worldPivotX, worldPivotY = 0, 0
    if nSelections > 0 then
        selections.forEach('primary', function(id, node)
            local worldX, worldY = space.getWorldSpace(node).transform:transformPoint(0, 0)
            worldPivotX, worldPivotY = worldPivotX + worldX, worldPivotY + worldY
        end)
        worldPivotX, worldPivotY = worldPivotX / nSelections, worldPivotY / nSelections
    end
end


--
-- Mouse
--

local pressedAngle

function mode_rotate.mousemoved(screenMouseX, screenMouseY, screenMouseDX, screenMouseDY, isTouch)
    if love.mouse.isDown(1) then
        local worldMouseX, worldMouseY = camera.getTransform():inverseTransformPoint(screenMouseX, screenMouseY)
        local prevScreenMouseX, prevScreenMouseY = screenMouseX - screenMouseDX, screenMouseY - screenMouseDY
        local prevWorldMouseX, prevWorldMouseY = camera.getTransform():inverseTransformPoint(prevScreenMouseX, prevScreenMouseY)

        -- Compute delta angle
        local prevAngle = math.atan2(prevWorldMouseY - worldPivotY, prevWorldMouseX - worldPivotX)
        local angle = math.atan2(worldMouseY - worldPivotY, worldMouseX - worldPivotX)
        if snapToIncrement then
            local increment = incrementDegrees * math.pi / 180
            prevAngle = increment * math.floor(0.5 + (prevAngle - pressedAngle) / increment) + pressedAngle
            angle = increment * math.floor(0.5 + (angle - pressedAngle) / increment) + pressedAngle
        end
        local dAngle = angle - prevAngle
        local sinDAngle, cosDAngle = math.sin(dAngle), math.cos(dAngle)

        -- Actually rotate nodes
        selections.forEach('primary', function(id, node)
            -- Update rotation
            node.rotation = node.rotation + dAngle
            while node.rotation > math.pi do
                node.rotation = node.rotation - 2 * math.pi
            end
            while node.rotation < -math.pi do
                node.rotation = node.rotation + 2 * math.pi
            end

            -- Don't update positions if only one node (pivot is its own origin) to avoid floating point inaccuracy issues
            if nSelections > 1 then
                -- Update position by rotating pivot->node delta vector in parent-space
                local parentWorldTransform = space.getParentWorldSpace(node).transform
                local parentPivotX, parentPivotY = parentWorldTransform:inverseTransformPoint(worldPivotX, worldPivotY)
                local dX, dY = node.x - parentPivotX, node.y - parentPivotY
                dX, dY = dX * cosDAngle - dY * sinDAngle, dX * sinDAngle + dY * cosDAngle
                node.x, node.y = dX + parentPivotX, dY + parentPivotY
            end
        end)
    end
end

function mode_rotate.mousepressed(screenMouseX, screenMouseY, button)
    if button == 1 then
        local pressedWorldMouseX, pressedWorldMouseY = camera.getTransform():inverseTransformPoint(screenMouseX, screenMouseY)
        pressedAngle = math.atan2(pressedWorldMouseY - worldPivotY, pressedWorldMouseX - worldPivotX)
    end
end

function mode_rotate.getCursorName()
    -- Pick cursor orientation based on the quadrant it is in relative to the pivot
    if nSelections == 0 then
        return 'rotate_se'
    end
    local worldMouseX, worldMouseY = camera.getTransform():inverseTransformPoint(love.mouse.getPosition())
    return 'rotate_' .. (worldMouseY > worldPivotY and 's' or 'n') .. (worldMouseX > worldPivotX and 'e' or 'w')
end


--
-- UI
--

function mode_rotate.uiupdate()
    snapToIncrement = ui.checkbox('snap to increment', snapToIncrement)
    if snapToIncrement then
        incrementDegrees = ui.numberInput('increment (degrees)', incrementDegrees)
    end
end


return mode_rotate