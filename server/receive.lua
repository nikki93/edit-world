local server = require 'server.init'
local locals = require 'server.locals'
local settings = require 'common.settings'


local share = server.share


function server.receive(clientId, msg, ...)
    if msg == 'setSetting' then
        local name, value = ...
        share.settings[name] = value
    end

    if msg == 'postOpened' then
        local post = ...

        -- Settings
        share.settings = post.data.settings

        -- Fill default settings where missing
        for k, v in pairs(settings.DEFAULTS) do
            if share.settings[k] == nil then
                share.settings[k] = v
            end
        end

        -- Nodes
        locals.nodeManager:load(post.data.nodes)
    end
end