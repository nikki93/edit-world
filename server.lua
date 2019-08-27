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

    do -- Settings
        share.settings = SETTINGS_DEFAULTS
    end

    do -- Nodes
        share.nodes = {}
    end

    do -- Locks
        share.locks = {}
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

    if msg == 'setSetting' then
        local name, value = ...
        share.settings[name] = value
    end

    if msg == 'postOpened' then
        local post = ...

        share.settings = post.data.settings

        if post.data.backgroundColor then -- Migrate old background color
            share.settings.backgroundColor = post.data.backgroundColor
        end

        share.nodes = post.data.nodes

        for id, node in pairs(share.nodes) do -- Migrate old nodes
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
    end

    if msg == 'addToGroup' then
        local parentId, childId = ...
        local parent, child = share.nodes[parentId], share.nodes[childId]
        if parent and child then
            if child.parentId ~= parent.id and parent.type == 'group' then
                child.parentId = parent.id
                parent.group.childrenIds[child.id] = true
            end
        end
    end

    if msg == 'removeFromGroup' then
        local parentId, childId = ...
        local parent, child = share.nodes[parentId], share.nodes[childId]
        if parent and child then
            if child.parentId == parent.id then
                child.parentId = nil
                parent.group.childrenIds[child.id] = nil
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

    do -- Edits, deletions, locks
        for id, clientId in pairs(share.locks) do -- Lock releases
            local home = homes[clientId]
            if not (home and home.selected and home.selected[id]) then
                share.locks[id] = nil
            end
        end
        for clientId in pairs(share.players) do
            local selected, deleted = homes[clientId].selected or {}, homes[clientId].deleted or {}
            for id in pairs(deleted) do -- Remove deleteds
                share.nodes[id] = nil
            end
            for id, node in pairs(selected) do -- Apply edits, respecting locks and tracking lock acquisitions
                if not share.locks[id] or share.locks[id] == clientId then
                    share.locks[id] = clientId
                    share.nodes[id] = node
                end
            end
        end
    end

    do -- Run update rules
        for id, node in pairs(share.nodes) do
            runUpdateRules(node, function(id)
                return share.nodes[id]
            end)
        end
    end
end
