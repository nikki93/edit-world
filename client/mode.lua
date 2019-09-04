local mode_common = require 'client.mode_common'


local mode = {}


local modes = {}

modes.none = require 'client.mode_none'
modes.grab = require 'client.mode_grab'
modes.rotate = require 'client.mode_rotate'
modes.resize = require 'client.mode_resize'


local currentMode = 'none'

local function fireEvent(eventName, ...)
    local func = modes[currentMode][eventName]
    if func then
        func(...)
    else
        func = mode_common[eventName]
        if func then
            func(...)
        end
    end
end


function mode.setMode(newMode)
    fireEvent('exit')
    currentMode = newMode
    fireEvent('enter')
end


function mode.update(dt)
    fireEvent('update', dt)
end


function mode.drawWorldSpace()
    fireEvent('drawWorldSpace')
end

function mode.drawScreenSpace()
    fireEvent('drawScreenSpace')
end


function mode.keypressed(key, scancode, isRepeat)
    fireEvent('keypressed', key, scancode, isRepeat)
end

function mode.keyreleased(key, scancode)
    fireEvent('keyreleased', key, scancode)
end


function mode.mousepressed(x, y, button, isTouch, presses)
    fireEvent('mousepressed', x, y, button, isTouch, presses)
end

function mode.mousereleased(x, y, button, isTouch, presses)
    fireEvent('mousereleased', x, y, button, isTouch, presses)
end


return mode