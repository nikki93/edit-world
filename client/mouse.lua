local client = require 'client.init'
local mode = require 'client.mode'
local camera = require 'client.camera'


function client.mousepressed(x, y, button, isTouch, presses)
    mode.mousepressed(x, y, button, isTouch, presses)
end

function client.mousereleased(x, y, button, isTouch, presses)
    mode.mousereleased(x, y, button, isTouch, presses)
end

function client.wheelmoved(x, y)
    if y > 0 then
        camera.zoomIn()
    end
    if y < 0 then
        camera.zoomOut()
    end
end