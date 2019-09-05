local client = require 'client.init'
local mode = require 'client.mode'
local hud = require 'client.hud'


local hudCaptured = false

function client.mousepressed(x, y, button, isTouch, presses)
    hudCaptured = hud.mousepressed(x, y, button, isTouch, presses)
    if not hudCaptured then
        mode.mousepressed(x, y, button, isTouch, presses)
    end
end

function client.mousereleased(x, y, button, isTouch, presses)
    if hudCaptured then
        hud.mousereleased(x, y, button, isTouch, presses)
    else
        mode.mousereleased(x, y, button, isTouch, presses)
    end
end

function client.mousemoved(x, y, dx, dy, isTouch)
    if hudCaptured then
        hud.mousemoved(x, y, dx, dy, isTouch)
    else
        mode.mousemoved(x, y, dx, dy, isTouch)
    end
end

function client.wheelmoved(x, y)
    mode.wheelmoved(x, y)
end