require 'common'


--- SERVER

local server = cs.server

if USE_CASTLE_CONFIG then
    server.useCastleConfig()
else
    server.enabled = true
    server.start('22122')
end

local share = server.share
local homes = server.homes


--- UTIL


--- LOAD

function server.load()
    do -- Players
        share.players = {}
    end

    do -- Background
        share.backgroundColor = { r = 1, g = 0.98, b = 0.98 }
    end

    do -- Nodes
        share.nodes = {}
    end

    do -- Names
        share.names = {}
    end
end


--- CONNECT

function server.connect(clientId)
    do -- New player
        share.players[clientId] = {}
        local player = share.players[clientId]

        player.x, player.y = 4 * G * (2 * math.random() - 1), 4 * G * (2 * math.random() - 1)
    end
end


--- DISCONNECT

function server.disconnect(clientId)
    do -- Remove player
        local player = share.players[clientId]
        share.players[clientId] = nil
    end
end


--- RECEIVE

function server.receive(clientId, msg, ...)
    local player = share.players[clientId]

    if msg == 'setBackgroundColor' then
        share.backgroundColor = ...
    end

    if msg == 'postOpened' then
        local post = ...

        share.backgroundColor = post.data.backgroundColor

        share.nodes = post.data.nodes

        for id, node in pairs(share.nodes) do -- Migrate old formats
            for k, v in pairs(NODE_COMMON_DEFAULTS) do
                if node[k] == nil then
                    node[k] = v
                end
            end
            for k, v in pairs(NODE_TYPE_DEFAULTS[node.type]) do
                if node[node.type][k] == nil then
                    node[node.type][k] = v
                end
            end
        end

        share.names = {}
        for id, node in pairs(share.nodes) do
            if node.name ~= '' then
                share.names[node.name] = node.id
            end
        end
    end
end


--- UPDATE

function server.update(dt)
    do -- Player mes
        for clientId, player in pairs(share.players) do
            player.me = homes[clientId].me
        end
    end

    do -- Player motion
        for clientId, player in pairs(share.players) do
            local homeX, homeY = homes[clientId].x, homes[clientId].y
            if homeX and homeY then
                player.x, player.y = homeX, homeY
            end
        end
    end

    do -- Edits
        for clientId in pairs(share.players) do
            local selected, deleted = homes[clientId].selected or {}, homes[clientId].deleted or {}
            for id in pairs(deleted) do -- Remove deleteds, tracking name changes
                selected[id] = nil

                local currNode = share.nodes[id]
                if currNode and currNode.name ~= '' then
                    share.names[currNode.name] = nil
                end

                share.nodes[id] = nil
            end
            for id, node in pairs(selected) do -- Update selecteds, tracking name changes
                local currNode = share.nodes[id]
                local currName = (currNode and currNode.name) or ''
                if currName ~= node.name then
                    if currName ~= '' then
                        share.names[currName] = nil
                    end
                    if node.name ~= '' and not share.names[node.name] then
                        share.names[node.name] = id
                    end
                end

                share.nodes[id] = node
            end
        end
    end
end
