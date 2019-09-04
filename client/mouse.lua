local client = require 'client.init'
local mode = require 'client.mode'


function client.mousepressed(x, y, button, isTouch, presses)
    mode.mousepressed(x, y, button, isTouch, presses)
end

function client.mousereleased(x, y, button, isTouch, presses)
    mode.mousereleased(x, y, button, isTouch, presses)
end