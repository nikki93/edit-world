local client = require 'client.init'
local ui = castle.ui
local mode = require 'client.mode'
local selections = require 'client.selections'
local locals = require 'client.locals'


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
            ui.markdown('---')

            local function allowedChange(func)
                return function(...)
                    -- TODO(nikki): Make sure not a conflicting selection
                    func(...)
                end
            end

            selections.forEach('primary', function(id, node)
                ui.box('node-' .. node.id, function()
                    locals.nodeManager:getProxy(node):ui({
                        validateChange = allowedChange,
                    })
                end)
                ui.markdown('---')
            end)
        end)
        ui.tab('world', function()
        end)
    end)
end