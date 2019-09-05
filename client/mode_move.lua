local selections = require 'client.selections'
local space = require 'client.space'
local camera = require 'client.camera'


local mode_move = {}


function mode_move.move(screenPrevMouseX, screenPrevMouseY, screenMouseX, screenMouseY)
    local worldPrevMouseX, worldPrevMouseY = camera.getTransform():inverseTransformPoint(screenPrevMouseX, screenPrevMouseY)
    local worldMouseX, worldMouseY = camera.getTransform():inverseTransformPoint(screenMouseX, screenMouseY)

    selections.forEach('primary', function(id, node)
        local transform = space.getWorldSpace(node).transform
        local localPrevMouseX, localPrevMouseY = transform:inverseTransformPoint(worldPrevMouseX, worldPrevMouseY)
        local localMouseX, localMouseY = transform:inverseTransformPoint(worldMouseX, worldMouseY)
        local localMouseDX, localMouseDY = localMouseX - localPrevMouseX, localMouseY - localPrevMouseY
        node.x, node.y = node.x + localMouseDX, node.y + localMouseDY
    end)
end

function mode_move.mousemoved(mouseX, mouseY, mouseDX, mouseDY, isTouch)
    if love.mouse.isDown(1) then
        mode_move.move(mouseX - mouseDX, mouseY - mouseDY, mouseX, mouseY)
    end
end


return mode_move