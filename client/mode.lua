local mode_common = require 'client.mode_common'


local mode = {}


mode.modes = {}

mode.modes.none = require 'client.mode_none'
mode.modes.move = require 'client.mode_move'
mode.modes.rotate = require 'client.mode_rotate'
mode.modes.resize = require 'client.mode_resize'

mode.order = {
    'none',
    'move',
    'rotate',
    'resize',
}


local currentMode = 'none'

local function fireEvent(eventName, ...)
    local func = mode.modes[currentMode][eventName]
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

function mode.getMode()
    return currentMode
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
    local number = tonumber(key)
    if number ~= nil and 1 <= number and number <= #mode.order then
        mode.setMode(mode.order[number])
        return
    end

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

function mode.mousemoved(x, y, dx, dy, isTouch)
    fireEvent('mousemoved', x, y, dx, dy, isTouch)
end

function mode.wheelmoved(x, y)
    fireEvent('wheelmoved', x, y)
end


return mode