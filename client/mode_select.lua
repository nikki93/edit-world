local selections = require 'client.selections'
local locals = require 'client.locals'
local graphics_utils = require 'common.graphics_utils'
local space = require 'client.space'
local camera = require 'client.camera'
local ui_utils = require 'common.ui_utils'
local ui = castle.ui
local mode_common = require 'client.mode_common'


local mode_select = {}


--
-- Common
--

function mode_select.newNode()
    selections.deselectAll()
    local newNode = locals.nodeManager:new({ isControlled = true })
    local windowW, windowH = love.graphics.getDimensions()
    newNode.x, newNode.y = camera.getTransform():inverseTransformPoint(0.5 * windowW, 0.5 * windowH)
    selections.attemptPrimarySelect(newNode.id)
end

function mode_select.deleteNodes()
    selections.forEach('primary', function(id)
        locals.nodeManager:delete(id)
    end)
end

function mode_select.cloneNodes()
    selections.forEach('primary', function(id)
        local newNode = locals.nodeManager:clone(id, { isControlled = true })
        newNode.x, newNode.y = newNode.x + 1, newNode.y + 1
        selections.deselect(id, 'primary')
        selections.attemptPrimarySelect(newNode.id)
    end)
end


--
-- Keyboard
--

function mode_select.keypressed(key)
    if key == 'n' then
        mode_select.newNode()
    end
    if key == 'c' then
        mode_select.cloneNodes()
    end
    if key == 'backspace' or key == 'delete' then
        mode_select.deleteNodes()
    end
end


--
-- Mouse
--

function mode_select.mouseClickSelect(screenMouseX, screenMouseY)
    -- Pick the next thing that's not already selected
    local pick = mode_common.mousePick(screenMouseX, screenMouseY, function(node)
        return selections.isSelected(node.id, 'primary', 'conflicting')
    end)

    -- Deselect everything first if not multi-selecting, then select the pick
    if not (love.keyboard.isDown('lctrl') or love.keyboard.isDown('rctrl')) then
        selections.deselectAll()
    end
    if pick then
        selections.attemptPrimarySelect(pick.id)
    end
end

function mode_select.mousepressed(x, y, button)
    if button == 1 then
        mode_select.mouseClickSelect(x, y)
    end
end

function mode_select.getCursorName()
    return 'normal'
end


--
-- UI
--

function mode_select.uiupdate()
    ui_utils.row('top-bar', function()
        if ui.button('new') then
            mode_select.newNode()
        end
    end, function()
        if selections.isAnySelected('primary') and ui.button('delete', { kind = 'danger' }) then
            mode_select.deleteNodes()
        end
    end, function()
        if selections.isAnySelected('primary') and ui.button('clone') then
            mode_select.cloneNodes()
        end
    end)
end


return mode_select