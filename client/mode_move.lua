local selections = require 'client.selections'
local space = require 'client.space'
local camera = require 'client.camera'
local ui = castle.ui
local ui_utils = require 'common.ui_utils'


local mode_move = {}


local snapToGrid = true
local gridSizeX, gridSizeY = 1, 1
local moveAlong = 'both x and y'


--
-- Update / mouse
--

-- We use `.update` to take into account camera motion while the mouse is still

local mouseDown = false
local prevWorldMouseX, prevWorldMouseY
local pressedWorldMouseX, pressedWorldMouseY

function mode_move.update(dt)
    if mouseDown then
        local worldMouseX, worldMouseY = camera.getTransform():inverseTransformPoint(love.mouse.getPosition())

        if snapToGrid then -- Quantize world-space mouse position to grid
            if not (pressedWorldMouseX and pressedWorldMouseY) then
                pressedWorldMouseX, pressedWorldMouseY = worldMouseX, worldMouseY
            end
            worldMouseX = gridSizeX * math.floor(0.5 + (worldMouseX - pressedWorldMouseX) / gridSizeX) + pressedWorldMouseX
            worldMouseY = gridSizeY * math.floor(0.5 + (worldMouseY - pressedWorldMouseY) / gridSizeY) + pressedWorldMouseY
        end

        if not (prevWorldMouseX and prevWorldMouseY) then
            prevWorldMouseX, prevWorldMouseY = worldMouseX, worldMouseY
        end

        selections.forEach('primary', function(id, node)
            local transform = space.getParentWorldSpace(node).transform
            local localPrevMouseX, localPrevMouseY = transform:inverseTransformPoint(prevWorldMouseX, prevWorldMouseY)
            local localMouseX, localMouseY = transform:inverseTransformPoint(worldMouseX, worldMouseY)
            local localMouseDX, localMouseDY = localMouseX - localPrevMouseX, localMouseY - localPrevMouseY
            if moveAlong ~= 'y only' then
                node.x = node.x + localMouseDX
            end
            if moveAlong ~= 'x only' then
                node.y = node.y + localMouseDY
            end
        end)

        prevWorldMouseX, prevWorldMouseY = worldMouseX, worldMouseY
    end
end

function mode_move.mousepressed(x, y, button, isTouch, presses)
    if button == 1 then
        prevWorldMouseX, prevWorldMouseY = nil, nil
        pressedWorldMouseX, pressedWorldMouseY = camera.getTransform():inverseTransformPoint(x, y)
        mouseDown = true
    end
end

function mode_move.mousereleased(x, y, button, isTouch, presses)
    if button == 1 then
        mouseDown = false
    end
end

function mode_move.getCursorName()
    return 'scroll'
end


--
-- UI
--

function mode_move.uiupdate()
    snapToGrid = ui.checkbox('snap to grid', snapToGrid)
        if snapToGrid then
        ui_utils.row('grid-size', function()
            gridSizeX = ui.numberInput('grid size x', gridSizeX)
        end, function()
            gridSizeY = ui.numberInput('grid size y', gridSizeY)
        end)
    end

    moveAlong = ui.dropdown('move along axes', moveAlong, { 'both x and y', 'x only', 'y only' })
end


return mode_move