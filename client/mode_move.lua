local selections = require 'client.selections'
local space = require 'client.space'
local camera = require 'client.camera'


local mode_move = {}


function mode_move.move(prevWorldMouseX, prevWorldMouseY, worldMouseX, worldMouseY)
    selections.forEach('primary', function(id, node)
        local transform = space.getWorldSpace(node).transform
        local localPrevMouseX, localPrevMouseY = transform:inverseTransformPoint(prevWorldMouseX, prevWorldMouseY)
        local localMouseX, localMouseY = transform:inverseTransformPoint(worldMouseX, worldMouseY)
        local localMouseDX, localMouseDY = localMouseX - localPrevMouseX, localMouseY - localPrevMouseY
        node.x, node.y = node.x + localMouseDX, node.y + localMouseDY
    end)
end


-- We use `.update` instead of `.mousemoved` to take into account camera motion while the mouse is still

local prevWorldMouseX, prevWorldMouseY

function mode_move.update(dt)
    local worldMouseX, worldMouseY = camera.getTransform():inverseTransformPoint(love.mouse.getPosition())
    if not (prevWorldMouseX and prevWorldMouseY) then
        prevWorldMouseX, prevWorldMouseY = worldMouseX, worldMouseY
    end
    if love.mouse.isDown(1) then
        mode_move.move(prevWorldMouseX, prevWorldMouseY, worldMouseX, worldMouseY)
    end
    prevWorldMouseX, prevWorldMouseY = worldMouseX, worldMouseY
end


return mode_move