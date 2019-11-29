local client = require 'client.init'
local ui = castle.ui
local mode = require 'client.mode'
local selections = require 'client.selections'
local locals = require 'client.locals'


local share = client.share


local function uiForNode(node, isConflicting)
    if isConflicting then -- Show which other player is locking this node
        local player = share.players[share.nodes.locks[node.id]]
        if player and player.me and player.me.username then
            if player.me.photoUrl then
                ui.box('lock-description', { flexDirection = 'row' }, function()
                    ui.box('locked-by', { marginRight = 10, justifyContent = 'center' }, function()
                        ui.markdown('🔒 locked by')
                    end)
                    ui.box('lock-photo', { maxWidth = 16, maxHeight = 16, justifyContent = 'center' }, function()
                        ui.image(player.me.photoUrl)
                    end)
                    ui.box('lock-username', { flex = 1, marginLeft = '8px', justifyContent = 'center' }, function()
                        ui.markdown(player.me.username)
                    end)
                end)
            else
                ui.markdown('🔒 locked by ' .. player.username)
            end
        else
            ui.markdown('🔒 locked by unknown')
        end
    end

    ui.box('node-' .. node.id, isConflicting and {
        border = '1px solid red',
        padding = 2,
        marginBottom = 2,
    } or {}, function()
        locals.nodeManager:getProxy(node):ui({
            validateChange = function(func)
                if isConflicting then
                    return function()
                        print("can't edit this node because it is locked")
                    end
                else
                    return func
                end
            end,
        })
    end)

    ui.markdown('---')
end


local modeSectionOpen = true

function client.uiupdate()
    if not client.connected then
        ui.markdown('connecting...')
        return
    end

    ui.pane('toolbar', function()
        for _, modeName in ipairs(mode.order) do
            if ui.button(modeName) then
                mode.setMode(modeName)
            end
        end
    end)

    ui.tabs('main', function()
        -- Nodes
        ui.tab('nodes', function()
            -- Mode
            modeSectionOpen = ui.section(mode.getMode(), {
                open = modeSectionOpen,
            }, function()
                mode.uiupdate()
            end)
            ui.markdown('---')

            -- Nodes
            selections.forEach('primary', function(id, node)
                uiForNode(node, false)
            end)
            selections.forEach('conflicting', function(id, node)
                uiForNode(node, true)
            end)
        end)

        -- World
        ui.tab('world', function()
            -- Background color
            local bgc = share.settings.backgroundColor
            ui.colorPicker('background color', bgc.r, bgc.g, bgc.b, 1, {
                onChange = function(c)
                    client.send('setSetting', 'backgroundColor', c)
                end,
            })

            -- Post world
            if ui.button('post world!') then
                network.async(function()
                    castle.post.create {
                        message = 'A world we created!',
                        media = 'capture',
                        data = {
                            -- Settings
                            settings = share.settings,

                            -- Nodes
                            nodes = locals.nodeManager:save(),
                        },
                    }
                end)
            end
        end)
    end)
end