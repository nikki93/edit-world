local selections = require 'client.selections'
local space = require 'client.space'
local camera = require 'client.camera'


local mode_resize = {}


function mode_resize.resize(prevWorldMouseX, prevWorldMouseY, worldMouseX, worldMouseY)
    selections.forEach('primary', function(id, node)
        local transform = space.getWorldSpace(node).transform
        local prevLocalMouseX, prevLocalMouseY = transform:inverseTransformPoint(prevWorldMouseX, prevWorldMouseY)
        local localMouseX, localMouseY = transform:inverseTransformPoint(worldMouseX, worldMouseY)
        if math.abs(prevLocalMouseX) >= 0.5 and math.abs(localMouseX) >= 0.5 then
            node.width = math.max(1, node.width * localMouseX / prevLocalMouseX)
        end
        if math.abs(prevLocalMouseY) >= 0.5 and math.abs(localMouseY) >= 0.5 then
            node.height = math.max(1, node.height * localMouseY / prevLocalMouseY)
        end
    end)
end


function mode_resize.mousemoved(screenMouseX, screenMouseY, screenMouseDX, screenMouseDY, isTouch)
    if love.mouse.isDown(1) then
        local worldMouseX, worldMouseY = camera.getTransform():inverseTransformPoint(screenMouseX, screenMouseY)
        local prevScreenMouseX, prevScreenMouseY = screenMouseX - screenMouseDX, screenMouseY - screenMouseDY
        local prevWorldMouseX, prevWorldMouseY = camera.getTransform():inverseTransformPoint(prevScreenMouseX, prevScreenMouseY)
        mode_resize.resize(prevWorldMouseX, prevWorldMouseY, worldMouseX, worldMouseY)
    end
end


return mode_resize