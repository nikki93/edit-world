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
    end
end

function mode_rotate.getCursorName()
    return 'rotate_se'
end


return mode_rotate