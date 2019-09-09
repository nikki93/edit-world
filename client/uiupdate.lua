local client = require 'client.init'
local ui = castle.ui
local mode = require 'client.mode'


local modeSectionOpen = true


function client.uiupdate()
    if not client.connected then
        ui.markdown('connecting...')
        return
    end

    ui.tabs('main', function()
        ui.tab('nodes', function()
            modeSectionOpen = ui.section(mode.getMode(), {
                open = modeSectionOpen,
            }, function()
                mode.uiupdate()
            end)
        end)
        ui.tab('world', function()
        end)
    end)
end