local client = require 'client.init'
local selections = require 'client.selections'
local ui = castle.ui
local mode_none = require 'client.mode_none'


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
            mode_none.newNode()
        end
    end, function()
        if selections.isAnySelected('primary') and ui.button('delete', { kind = 'danger' }) then
            mode_none.deleteNodes()
        end
    end, function()
        if selections.isAnySelected('primary') and ui.button('clone') then
            mode_none.cloneNodes()
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