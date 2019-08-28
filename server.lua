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
        for clientId in pairs(share.players) do -- Deletions
            if homes[clientId].deleted then
                for id in pairs(homes[clientId].deleted) do
                    local oldNode = share.nodes[id]
                    if share.locks[id] == clientId and oldNode then -- Check lock
                        if oldNode.parentId then
                            removeFromGroup(share.nodes[oldNode.parentId], oldNode)
                        end
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
                for id, newNode in pairs(homes[clientId].selected) do
                    if not share.locks[id] then -- Acquire lock
                        share.locks[id] = clientId
                    end
                    if share.locks[id] == clientId then -- Check lock
                        local oldNode = share.nodes[id]
                        if oldNode then
                            if oldNode.parentId == newNode.parentId then -- Keep parent, check tags
                                updateTagIndex(oldNode.parentId and share.nodes[oldNode.parentId], oldNode, newNode.tags)
                            else -- Change parent
                                if oldNode.parentId then
                                    removeFromGroup(share.nodes[oldNode.parentId], oldNode)
                                end
                                if newNode.parentId then
                                    addToGroup(share.nodes[newNode.parentId], newNode)
                                end
                            end
                        elseif newNode.parentId then
                            addToGroup(share.nodes[newNode.parentId], newNode)
                        end
                        share.nodes[id] = newNode -- Apply edits
                    end
                end
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
