local client = require 'client.init'
local ui = castle.ui
local mode = require 'client.mode'


function client.uiupdate()
    if not client.connected then
        ui.markdown('connecting...')
        return
    end

    ui.tabs('main', function()
        ui.tab('nodes', function()
            mode.uiupdate()
        end)
        ui.tab('world', function()
        end)
    end)
end