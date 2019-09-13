local mode_common = require 'client.mode_common'


local mode = {}


--
-- Common
--

mode.modes = {}

mode.modes.select = require 'client.mode_select'
mode.modes.move = require 'client.mode_move'
mode.modes.rotate = require 'client.mode_rotate'
mode.modes.resize = require 'client.mode_resize'
mode.modes.attach = require 'client.mode_attach'

mode.order = {
    'select',
    'move',
    'rotate',
    'resize',
    'attach',
}


local currentMode = 'select'

local function fireEvent(eventName, ...)
    local func = mode.modes[currentMode][eventName]
    if func then
        return func(...)
    else
        func = mode_common[eventName]
        if func then
            return func(...)
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


--
-- Update
--

function mode.update(dt)
    fireEvent('update', dt)
end


--
-- Draw
--

function mode.drawNodeOverlays(...)
    fireEvent('drawNodeOverlays', ...)
end


--
-- Keyboard
--

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


--
-- Mouse
--

function mode.getCursorName()
    return fireEvent('getCursorName')
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


--
-- UI
--

function mode.uiupdate()
    fireEvent('uiupdate')
end


return mode