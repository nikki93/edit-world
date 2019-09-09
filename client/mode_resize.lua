local selections = require 'client.selections'
local space = require 'client.space'
local camera = require 'client.camera'


local mode_resize = {}


local nSelections
local worldPivotX, worldPivotY = 0, 0


--
-- Update
--

function mode_resize.update(dt)
    nSelections = selections.numSelections('primary')

    worldPivotX, worldPivotY = 0, 0
    selections.forEach('primary', function(id, node)
        local worldX, worldY = space.getWorldSpace(node).transform:transformPoint(0, 0)
        worldPivotX, worldPivotY = worldPivotX + worldX, worldPivotY + worldY
    end)
    worldPivotX, worldPivotY = worldPivotX / nSelections, worldPivotY / nSelections
end


--
-- Mouse
--

function mode_resize.mousemoved(screenMouseX, screenMouseY, screenMouseDX, screenMouseDY, isTouch)
    if love.mouse.isDown(1) then
        local worldMouseX, worldMouseY = camera.getTransform():inverseTransformPoint(screenMouseX, screenMouseY)
        local prevScreenMouseX, prevScreenMouseY = screenMouseX - screenMouseDX, screenMouseY - screenMouseDY
        local prevWorldMouseX, prevWorldMouseY = camera.getTransform():inverseTransformPoint(prevScreenMouseX, prevScreenMouseY)

        -- Actually scale nodes
        selections.forEach('primary', function(id, node)
            -- Update size by checking scaling of mouse position around pivot in local space
            local transform = space.getWorldSpace(node).transform
            local pivotLX, pivotLY = transform:inverseTransformPoint(worldPivotX, worldPivotY)
            local prevMouseLX, prevMouseLY = transform:inverseTransformPoint(prevWorldMouseX, prevWorldMouseY)
            local mouseLX, mouseLY = transform:inverseTransformPoint(worldMouseX, worldMouseY)
            local prevDLX, prevDLY = prevMouseLX - pivotLX, prevMouseLY - pivotLY
            local dLX, dLY = mouseLX - pivotLX, mouseLY - pivotLY
            node.width = node.width * dLX / prevDLX
            node.height = node.height * dLY / prevDLY

            if nSelections > 1 then
                -- Update position by checking scaling of mouse position around pivot in parent space
                -- TODO(nikki): This isn't really working...
                -- local transform = space.getParentWorldSpace(node).transform
                -- local pivotLX, pivotLY = transform:inverseTransformPoint(worldPivotX, worldPivotY)
                -- local prevMouseLX, prevMouseLY = transform:inverseTransformPoint(prevWorldMouseX, prevWorldMouseY)
                -- local mouseLX, mouseLY = transform:inverseTransformPoint(worldMouseX, worldMouseY)
                -- local prevDLX, prevDLY = prevMouseLX - pivotLX, prevMouseLY - pivotLY
                -- local dLX, dLY = mouseLX - pivotLX, mouseLY - pivotLY
                -- node.x = pivotLX + (node.x - pivotLX) * dLX / prevDLX
                -- node.y = pivotLY + (node.y - pivotLY) * dLY / prevDLY
            end
        end)
    end
end

function mode_resize.getCursorName()
    -- Pick cursor orientation based on the quadrant it is in relative to the pivot
    if nSelections == 0 then
        return 'size_se'
    end
    local worldMouseX, worldMouseY = camera.getTransform():inverseTransformPoint(love.mouse.getPosition())
    return 'size_' .. (worldMouseY > worldPivotY and 's' or 'n') .. (worldMouseX > worldPivotX and 'e' or 'w')
end


return mode_resize