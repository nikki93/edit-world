local server = require 'server.init'
local locals = require 'server.locals'


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

        -- Migrate old settings formats
        if post.data.backgroundColor then
            share.settings.backgroundColor = post.data.backgroundColor
        end

        -- Nodes
        locals.nodeManager:load(post.data.nodes)
    end
end