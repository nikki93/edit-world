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


--- LOCALS

local parentChildIndex = {}     -- `parent.id` -> `child.id` -> `true`, for all `child.parentId == parent.id`
local parentTagChildIndex = {}  -- `parent.id` -> `tag` -> `child.id` -> `true`, for all `child.tags[tag] and child.parentId == parent.id`


--- UTIL

local function getNodeWithId(id)
    return id and share.nodes[id]
end


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

        for id, node in pairs(share.nodes) do
            local newParentId = node.parentId
            if newParentId then
                local childIndex = parentChildIndex[newParentId]
                if not childIndex then
                    childIndex = {}
                    parentChildIndex[newParentId] = childIndex
                end
                childIndex[id] = true

                local tagChildIndex = parentTagChildIndex[newParentId]
                if not tagChildIndex then
                    tagChildIndex = {}
                    parentTagChildIndex[newParentId] = tagChildIndex
                end

                for tag in pairs(node.tags) do
                    local childIndex = tagChildIndex[tag]
                    if not childIndex then
                        childIndex = {}
                        tagChildIndex[tag] = childIndex
                    end
                    childIndex[id] = true
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
                    local oldNode = getNodeWithId(id)
                    if share.locks[id] == clientId and oldNode then -- Check lock
                        local oldParentId = oldNode.parentId
                        if oldParentId then
                            local childIndex = parentChildIndex[oldParentId]
                            if childIndex then
                                childIndex[nodeId] = nil
                                if not next(childIndex) then -- Empty?
                                    parentChildIndex[oldParentId] = nil
                                end
                            end
                            local tagChildIndex = parentTagChildIndex[oldParentId]
                            if tagChildIndex then
                                for tag in pairs(oldNode.tags) do
                                    local childIndex = tagChildIndex[tag]
                                    if childIndex then
                                        childIndex[nodeId] = nil
                                        if not next(childIndex) then
                                            tagChildIndex[tag] = nil
                                        end
                                    end
                                end
                                if not next(tagChildIndex) then
                                    parentTagChildIndex[oldParentId] = nil
                                end
                            end
                        end
                        share.nodes[id] = nil
                    end
                end
            end
        end
        for id, clientId in pairs(share.locks) do -- Release locks
            if not (homes[clientId] and homes[clientId].controlled and homes[clientId].controlled[id]) then
                share.locks[id] = nil
            end
        end
    end

    do -- Run think rules
        for id, node in pairs(share.nodes) do
            runThinkRules(node, getNodeWithId, { parentChildIndex = parentChildIndex, parentTagChildIndex = parentTagChildIndex })
        end
    end
end


--- CHANGING

local function applyDiff(t, diff)
    if diff == nil then return t end
    if diff.__exact then
        diff.__exact = nil
        return diff
    end
    t = (type(t) == 'table' or type(t) == 'userdata') and t or {}
    for k, v in pairs(diff) do
        if type(v) == 'table' then
            local r = applyDiff(t[k], v)
            if r ~= t[k] then
                t[k] = r
            end
        elseif v == DIFF_NIL then
            t[k] = nil
        else
            t[k] = v
        end
    end
    return t
end

function server.changing(clientId, homeDiff)
    local home = homes[clientId]
    local nodeDiffs = homeDiff.controlled
    if nodeDiffs then
        local rootExact = homeDiff.__exact or nodeDiffs.__exact
        for nodeId, nodeDiff in pairs(nodeDiffs) do
            if nodeId ~= '__exact' and not share.locks[nodeId] or share.locks[nodeId] == clientId then -- Not locked, or locked by us
                share.locks[nodeId] = clientId -- Acquire lock

                local oldNode = share.nodes[nodeId]
                local oldParentId = oldNode and oldNode.parentId
                if oldParentId then
                    if nodeDiff.parentId then -- Parent changed, remove from `parentChildIndex` for old parent
                        local childIndex = parentChildIndex[oldParentId]
                        if childIndex then
                            childIndex[nodeId] = nil
                            if not next(childIndex) then -- Empty?
                                parentChildIndex[oldParentId] = nil
                            end
                        end
                    end

                    if nodeDiff.parentId or nodeDiff.tags then -- Parent or tags changed, remove from `parentTagChildIndex` for old parent
                        local tagChildIndex = parentTagChildIndex[oldParentId]
                        if tagChildIndex then
                            for tag in pairs(oldNode.tags) do
                                local childIndex = tagChildIndex[tag]
                                if childIndex then
                                    childIndex[nodeId] = nil
                                    if not next(childIndex) then
                                        tagChildIndex[tag] = nil
                                    end
                                end
                            end
                            if not next(tagChildIndex) then
                                parentTagChildIndex[oldParentId] = nil
                            end
                        end
                    end
                end

                local newNode
                if rootExact or nodeDiff.__exact then
                    nodeDiff.__exact = nil
                    newNode = nodeDiff
                    share.nodes[nodeId] = newNode
                    nodeDiff.__exact = true
                elseif nodeDiff == '__NIL' then
                    newNode = nil
                    share.nodes[nodeId] = nil
                else
                    share.nodes[nodeId] = applyDiff(oldNode, nodeDiff)
                    newNode = share.nodes[nodeId]
                end
                local newParentId = newNode and newNode.parentId
                if newParentId then
                    if nodeDiff.parentId then -- Parent changed, add to `parentChildIndex` for new parent
                        local childIndex = parentChildIndex[newParentId]
                        if not childIndex then
                            childIndex = {}
                            parentChildIndex[newParentId] = childIndex
                        end
                        childIndex[nodeId] = true
                    end

                    if nodeDiff.parentId or nodeDiff.tags then -- Parent or tags changed, add to `parentTagChildIndex` for new parent
                        local tagChildIndex = parentTagChildIndex[newParentId]
                        if not tagChildIndex then
                            tagChildIndex = {}
                            parentTagChildIndex[newParentId] = tagChildIndex
                        end

                        for tag in pairs(newNode.tags) do
                            local childIndex = tagChildIndex[tag]
                            if not childIndex then
                                childIndex = {}
                                tagChildIndex[tag] = childIndex
                            end
                            childIndex[nodeId] = true
                        end
                    end
                end
            end
        end
    end
end
