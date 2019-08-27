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

    do -- Edits, deletions, locks, parenting
        local oldParentIds, newParentIds = {}, {}
        for clientId in pairs(share.players) do -- Deletions
            if homes[clientId].deleted then
                for id in pairs(homes[clientId].deleted) do
                    if share.locks[id] == clientId and share.nodes[id] then -- Check lock
                        oldParentIds[id] = share.nodes[id].parentId -- Track unparent
                        share.nodes[id] = nil
                    end
                end
            end
        end
        for id, clientId in pairs(share.locks) do -- Release locks
            if not (homes[clientId] and homes[clientId].selected and homes[clientId].selected[id]) then
                share.locks[id] = nil
            end
        end
        for clientId in pairs(share.players) do -- Edits
            if homes[clientId].selected then
                for id, node in pairs(homes[clientId].selected) do
                    if not share.locks[id] then -- Acquire lock
                        share.locks[id] = clientId
                    end
                    if share.locks[id] == clientId then -- Check lock
                        if share.nodes[id] and share.nodes[id].parentId ~= node.parentId then -- Track reparent
                            oldParentIds[id] = share.nodes[id].parentId
                            newParentIds[id] = node.parentId
                        end
                        share.nodes[id] = node -- Apply edits
                    end
                end
            end
        end
        for childId, oldParentId in pairs(oldParentIds) do -- Apply unparents
            local oldParent = share.nodes[oldParentId]
            if oldParent and oldParent.type == 'group' then
                oldParent.group.childrenIds[childId] = nil
            end
        end
        for childId, newParentId in pairs(newParentIds) do -- Apply parents
            local newParent = share.nodes[newParentId]
            if newParent and newParent.type == 'group' then
                newParent.group.childrenIds[childId] = true
            else
                share.nodes[childId].parentId = nil
            end
        end
    end

    do -- Run think rules
        for id, node in pairs(share.nodes) do
            runThinkRules(node, function(id)
                return share.nodes[id]
            end)
        end
    end
end
