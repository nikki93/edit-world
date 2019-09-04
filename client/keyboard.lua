local client = require 'client.init'
local mode = require 'client.mode'


function client.keypressed(key, scancode, isRepeat)
    mode.keypressed(key, scancode, isRepeat)
end

function client.keyreleased(key, scancode)
    mode.keyreleased(key, scancode)
end