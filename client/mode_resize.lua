local selections = require 'client.selections'
local space = require 'client.space'
local camera = require 'client.camera'
local ui = castle.ui


local mode_resize = {}


local nSelections
local worldPivotX, worldPivotY = 0, 0

local maintainAspect = true
local resizeAlong = 'both width and height'


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
            local scaleX, scaleY = 1, 1
            if math.abs(prevMouseLX) >= 0.5 and math.abs(mouseLX) >= 0.5 then
                scaleX = dLX / prevDLX
            end
            if math.abs(prevMouseLY) >= 0.5 and math.abs(mouseLY) >= 0.5 then
                scaleY = dLY / prevDLY
            end
            if scaleX < 0 then
                scaleX = 1
            end
            if scaleY < 0 then
                scaleY = 1
            end
            if maintainAspect then
                if math.abs(mouseLX - prevMouseLX) > math.abs(mouseLY - prevMouseLY) then
                    scaleY = scaleX
                else
                    scaleX = scaleY
                end
            end
            if maintainAspect or resizeAlong ~= 'height only' then
                node.width = node.width * scaleX
            end
            if maintainAspect or resizeAlong ~= 'width only' then
                node.height = node.height * scaleY
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


--
-- UI
--

function mode_resize.uiupdate()
    maintainAspect = ui.checkbox('maintain aspect ratio', maintainAspect)
    if not maintainAspect then
        resizeAlong = ui.dropdown('resize along dimensions', resizeAlong, { 'both width and height', 'width only', 'height only' })
    end
end


return mode_resize