local selections = require 'client.selections'
local space = require 'client.space'
local camera = require 'client.camera'


local mode_rotate = {}


--
-- Mouse
--

function mode_rotate.mousemoved(screenMouseX, screenMouseY, screenMouseDX, screenMouseDY, isTouch)
    if love.mouse.isDown(1) then
        local worldMouseX, worldMouseY = camera.getTransform():inverseTransformPoint(screenMouseX, screenMouseY)
        local prevScreenMouseX, prevScreenMouseY = screenMouseX - screenMouseDX, screenMouseY - screenMouseDY
        local prevWorldMouseX, prevWorldMouseY = camera.getTransform():inverseTransformPoint(prevScreenMouseX, prevScreenMouseY)

        local nSelected = selections.numSelections('primary')
        if nSelected == 1 then -- Rotate single node around its own origin
            selections.forEach('primary', function(id, node)
                local transform = space.getWorldSpace(node).transform
                local prevLocalMouseX, prevLocalMouseY = transform:inverseTransformPoint(prevWorldMouseX, prevWorldMouseY)
                local localMouseX, localMouseY = transform:inverseTransformPoint(worldMouseX, worldMouseY)
                node.rotation = node.rotation + math.atan2(localMouseY, localMouseX) - math.atan2(prevLocalMouseY, prevLocalMouseX)
                while node.rotation > math.pi do
                    node.rotation = node.rotation - 2 * math.pi
                end
                while node.rotation < -math.pi do
                    node.rotation = node.rotation + 2 * math.pi
                end
            end)
        elseif nSelected > 1 then -- Rotate multiple nodes around the centroid of their origins (the 'pivot')
            -- Compute pivot
            local worldPivotX, worldPivotY = 0, 0
            selections.forEach('primary', function(id, node)
                local worldX, worldY = space.getWorldSpace(node).transform:transformPoint(0, 0)
                worldPivotX, worldPivotY = worldPivotX + worldX, worldPivotY + worldY
            end)
            worldPivotX, worldPivotY = worldPivotX / nSelected, worldPivotY / nSelected

            -- Compute delta angle
            local prevPivotMouseX, prevPivotMouseY = prevWorldMouseX - worldPivotX, prevWorldMouseY - worldPivotY
            local pivotMouseX, pivotMouseY = worldMouseX - worldPivotX, worldMouseY - worldPivotY
            local dAngle = math.atan2(pivotMouseY, pivotMouseX) - math.atan2(prevPivotMouseY, prevPivotMouseX)
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

                -- Update position by rotating pivot->node delta vector in parent-space
                local parentWorldTransform = space.getParentWorldSpace(node).transform
                local parentPivotX, parentPivotY = parentWorldTransform:inverseTransformPoint(worldPivotX, worldPivotY)
                local dX, dY = node.x - parentPivotX, node.y - parentPivotY
                dX, dY = dX * cosDAngle - dY * sinDAngle, dX * sinDAngle + dY * cosDAngle
                node.x, node.y = dX + parentPivotX, dY + parentPivotY
            end)
        end
    end
end

function mode_rotate.getCursorName()
    return 'rotate_se'
end


return mode_rotate