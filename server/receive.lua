local server = require 'server.init'


local share = server.share


function server.receive(clientId, msg, ...)
    if msg == 'setSetting' then
        local name, value = ...
        share.settings[name] = value
    end

    if msg == 'postOpened' then
        -- TODO(nikki): Load data
    end
end