local selections = require 'client.selections'
local space = require 'client.space'
local camera = require 'client.camera'


local mode_resize = {}


local nSelected
local worldPivotX, worldPivotY = 0, 0

--
-- Update
--

function mode_resize.update(dt)
    nSelected = selections.numSelections('primary')

    worldPivotX, worldPivotY = 0, 0
    selections.forEach('primary', function(id, node)
        local worldX, worldY = space.getWorldSpace(node).transform:transformPoint(0, 0)
        worldPivotX, worldPivotY = worldPivotX + worldX, worldPivotY + worldY
    end)
    worldPivotX, worldPivotY = worldPivotX / nSelected, worldPivotY / nSelected
end


--
-- Mouse
--

function mode_resize.mousemoved(screenMouseX, screenMouseY, screenMouseDX, screenMouseDY, isTouch)
    if love.mouse.isDown(1) then
        local worldMouseX, worldMouseY = camera.getTransform():inverseTransformPoint(screenMouseX, screenMouseY)
        local prevScreenMouseX, prevScreenMouseY = screenMouseX - screenMouseDX, screenMouseY - screenMouseDY
        local prevWorldMouseX, prevWorldMouseY = camera.getTransform():inverseTransformPoint(prevScreenMouseX, prevScreenMouseY)

        if nSelected == 1 then -- Scale single node around its own origin
            selections.forEach('primary', function(id, node)
                local transform = space.getWorldSpace(node).transform
                local prevLocalMouseX, prevLocalMouseY = transform:inverseTransformPoint(prevWorldMouseX, prevWorldMouseY)
                local localMouseX, localMouseY = transform:inverseTransformPoint(worldMouseX, worldMouseY)
                if math.abs(prevLocalMouseX) >= 0.5 and math.abs(localMouseX) >= 0.5 then
                    node.width = node.width * localMouseX / prevLocalMouseX
                end
                if math.abs(prevLocalMouseY) >= 0.5 and math.abs(localMouseY) >= 0.5 then
                    node.height = node.height * localMouseY / prevLocalMouseY
                end
            end)
        elseif nSelected > 1 then -- Scale multiple nodes around the centroid of their origins
            -- Compute scale factor
            local prevPivotMouseX, prevPivotMouseY = prevWorldMouseX - worldPivotX, prevWorldMouseY - worldPivotY
            local pivotMouseX, pivotMouseY = worldMouseX - worldPivotX, worldMouseY - worldPivotY
            local scaleX, scaleY = 1, 1
            if math.abs(prevPivotMouseX) >= 0.5 and math.abs(pivotMouseX) >= 0.5 then
                scaleX = pivotMouseX / prevPivotMouseX
            end
            if math.abs(prevPivotMouseY) >= 0.5 and math.abs(pivotMouseY) >= 0.5 then
                scaleY = pivotMouseY / prevPivotMouseY
            end

            -- Actually scale nodes
            selections.forEach('primary', function(id, node)
                -- Update size
                node.width, node.height = node.width * scaleX, node.height * scaleY

                -- Update position by scaling pivot->node delta vector in parent-space
                local parentWorldTransform = space.getParentWorldSpace(node).transform
                local parentPivotX, parentPivotY = parentWorldTransform:inverseTransformPoint(worldPivotX, worldPivotY)
                local dX, dY = node.x - parentPivotX, node.y - parentPivotY
                dX, dY = dX * scaleX, dY * scaleY
                node.x, node.y = dX + parentPivotX, dY + parentPivotY
            end)
        end
    end
end

function mode_resize.getCursorName()
    if nSelected == 0 then
        return 'size_se'
    end
    local screenMouseX, screenMouseY = love.mouse.getPosition()
    local worldMouseX, worldMouseY = camera.getTransform():inverseTransformPoint(screenMouseX, screenMouseY)
    local pivotMouseX, pivotMouseY = worldMouseX - worldPivotX, worldMouseY - worldPivotY
    local northSouth, westEast = pivotMouseY > 0 and 's' or 'n', pivotMouseX > 0 and 'e' or 'w'
    return 'size_' .. northSouth .. westEast
end


return mode_resize