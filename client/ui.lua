local client = require 'client.init'
local selections = require 'client.selections'
local locals = require 'client.locals'
local ui = castle.ui


local function uiRow(id, ...)
    local nArgs = select('#', ...)
    local args = { ... }
    ui.box(id, { flexDirection = 'row', alignItems = 'center' }, function()
        for i = 1, nArgs do
            ui.box(tostring(i), { flex = 1 }, args[i])
            if i < nArgs then
                ui.box('space', { width = 20 }, function() end)
            end
        end
    end)
end


local function uiNodesTopBar()
    uiRow('top-bar', function()
        if ui.button('new') then
            selections.deselectAll()
            local newNode = locals.nodeManager:new({ isControlled = true })
            selections.primarySelect(newNode.id)
        end
    end, function()
        if next(selections.primary) and ui.button('delete', { kind = 'danger' }) then
            -- TODO(nikki): Implement
        end
    end, function()
        if next(selections.primary) and ui.button('clone') then
            -- TODO(nikki): Implement
        end
    end)
end

local function uiNodesTab()
    uiNodesTopBar()
end


local function uiWorldTab()
end


function client.uiupdate()
    if not client.connected then
        return
    end

    ui.tabs('main', function()
        ui.tab('nodes', uiNodesTab)
        ui.tab('world', uiWorldTab)
    end)
end