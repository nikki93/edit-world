local table_utils = require 'common.table_utils'
local node_types = require 'common.node_types'
local lib = require 'common.lib'


local node_manager = {}


local NodeManager = {}
local NodeManagerMetatable = {
    __index = NodeManager,
}

function node_manager.new(opts)
    local self = setmetatable({}, NodeManagerMetatable)

    self.shared = assert(opts.shared)
    self.locks = assert(opts.locks)

    if opts.isServer then
        self.isServer = true
        self.isClient = false

    else
        self.isServer = false
        self.isClient = true

        self.controlled = assert(opts.controlled)
        self.clientId = assert(opts.clientId)
    end

    self.proxies = {}                   -- `node.id` -> local rule-facing proxy for that node
    self.parentChildIndex = {}          -- `parent.id` -> `child.id` -> `true` for all `child.parentId == parent.id`
    self.parentTagChildIndex = {}       -- `parent.id` -> `tag` -> `child.id` -> `true` for all `child.parentId == parent.id and child.tags[tag]`

    return self
end


--
-- New / delete
--

function NodeManager:new(opts)
    -- Initial data
    local newNodeData
    if opts.initialData then
        newNodeData = table_utils.clone(opts.initialData)
    else
        newNodeData = table_utils.clone(node_types.base.DEFAULTS)
        newNodeData[newNodeData.type] = table_utils.clone(node_types[newNodeData.type].DEFAULTS)
    end
    local id = lib.uuid()
    newNodeData.id = id
    newNodeData.rngState = love.math.newRandomGenerator(love.math.random()):getState()

    -- Insert in tables
    local newNode
    if self.isClient and opts.isControlled then
        self.controlled[id] = newNodeData
        newNode = self.controlled[id]
    else
        self.shared[id] = newNodeData
        newNode = self.shared[id]
    end

    -- Track parent
    local parentId = newNode.parentId
    if parentId then
        self:trackParent(id, parentId)
        for tag in pairs(newNode.tags) do
            self:trackTag(id, parentId, tag)
        end
    end

    return newNode
end

function NodeManager:clone(idOrNode, opts)
    local node = self:resolveIdOrNode(idOrNode)
    opts = table_utils.clone(opts)
    opts.initialData = node
    return self:new(opts)
end


function NodeManager:actuallyDelete(node)
    local id = node.id

    -- Detach children
    self:forEachChild(node, function(childId, child)
        self:setParent(child, nil)
    end)

    -- Detach parent
    self:setParent(node, nil)

    -- Remove from tables
    self.proxies[id] = nil
    self.locks[id] = nil
    if self.isClient then
        self.controlled[id] = nil
    end
    self.shared[id] = nil
end

function NodeManager:delete(idOrNode)
    local node = self:resolveIdOrNode(idOrNode)
    if self.isServer then
        self:actuallyDelete(node)
    elseif self.isClient and self.controlled[node.id] then
        node.deleting = true
    end
end


--
-- Type
--

function NodeManager:setType(idOrNode, newType)
    local node = self:resolveIdOrNode(idOrNode)
    if node.type == newType then
        return
    end

    node[node.type] = nil
    node.type = newType
    node[node.type] = table_utils.clone(node_types[node.type].DEFAULTS)

    self.proxies[node.id] = nil
end


--
-- Lookup
--

function NodeManager:getById(id)
    if self.isServer then
        return self.shared[id]
    else
        return self.controlled[id] or self.shared[id]
    end
end

function NodeManager:resolveIdOrNode(idOrNode)
    if type(idOrNode) == 'string' then
        return self:getById(idOrNode)
    else
        return idOrNode
    end
end

function NodeManager:forEach(func)
    if self.isServer then
        for id, node in pairs(self.shared) do
            if func(id, node) == false then
                return
            end
        end
    else
        for id, node in pairs(self.shared) do
            if not self.controlled[id] then
                if func(id, node) == false then
                    return
                end
            end
        end
        for id, node in pairs(self.controlled) do
            if func(id, node) == false then
                return
            end
        end
    end
end


--
-- Tracking
--

function NodeManager:trackParent(id, parentId)
    if parentId then
        local childIndex = self.parentChildIndex[parentId]
        if not childIndex then
            childIndex = {}
            self.parentChildIndex[parentId] = childIndex
        end
        childIndex[id] = true
    end
end

function NodeManager:untrackParent(id, parentId)
    if parentId then
        local childIndex = self.parentChildIndex[parentId]
        if childIndex then
            childIndex[id] = nil
            if not next(childIndex) then -- Emptied?
                self.parentChildIndex[parentId] = nil
            end
        end
    end
end


function NodeManager:trackTag(id, parentId, tag)
    if parentId then
        local tagChildIndex = self.parentTagChildIndex[parentId]
        if not tagChildIndex then
            tagChildIndex = {}
            self.parentTagChildIndex[parentId] = tagChildIndex
        end
        local childIndex = tagChildIndex[tag]
        if not childIndex then
            childIndex = {}
            tagChildIndex[tag] = childIndex
        end
        childIndex[id] = true
    end
end

function NodeManager:untrackTag(id, parentId, tag)
    if parentId then
        local tagChildIndex = self.parentTagChildIndex[parentId]
        if tagChildIndex then
            local childIndex = tagChildIndex[tag]
            if childIndex then
                childIndex[id] = nil
                if not next(childIndex) then -- Emptied?
                    tagChildIndex[tag] = nil
                end
            end
            if not next(tagChildIndex) then -- Emptied?
                self.parentChildIndex[parentId] = nil
            end
        end
    end
end


function NodeManager:trackDiff(id, diff, rootExact)
    local node = self:getById(id)
    if node then -- Update existing node
        local oldParentId = node.parentId
        local newParentId
        if rootExact or diff.__exact then
            newParentId = diff.parentId
        else
            newParentId = diff.parentId or oldParentId
        end
        if newParentId ~= oldParentId then -- Parent changed
            -- Untrack old parent
            for tag in pairs(node.tags) do
                self:untrackTag(id, oldParentId, tag)
            end
            self:untrackParent(id, oldParentId)

            -- Track new parent
            self:trackParent(id, newParentId)
            if diff.tags then
                if rootExact or diff.__exact or diff.tags.__exact then -- Exact new tags
                    for tag in pairs(diff.tags) do
                        if tag ~= '__exact' then
                            self:trackTag(id, newParentId, tag)
                        end
                    end
                else -- Diff'd new tags
                    for tag in pairs(node.tags) do
                        if diff.tags[tag] ~= lib.state.DIFF_NIL then -- Old tag and not removed in new
                            self:trackTag(id, newParentId, tag)
                        end
                    end
                    for tag in pairs(diff.tags) do
                        if not node.tags[tag] then -- New tag
                            self:trackTag(id, newParentId, tag)
                        end
                    end
                end
            end
        else -- Parent didn't change, just track tag changes
            if diff.tags then
                local parentId = newParentId
                if rootExact or diff.__exact or diff.tags.__exact then -- Exact new tags
                    for tag in pairs(node.tags) do
                        if not diff.tags[tag] then -- Old tag and removed in new
                            self:untrackTag(id, parentId, tag)
                        end
                    end
                    for tag in pairs(diff.tags) do
                        if tag ~= '__exact' and not node.tags[tag] then -- New tag
                            self:trackTag(id, parentId, tag)
                        end
                    end
                else
                    for tag, v in pairs(diff.tags) do
                        if v == lib.state.DIFF_NIL then -- Tag removed
                            self:untrackTag(id, parentId, tag)
                        else -- Tag added
                            self:trackTag(id, parentId, tag)
                        end
                    end
                end
            end
        end

        if diff.type ~= nil and node.type ~= diff.type then -- Type changed, invalidate proxy
            self.proxies[id] = nil
        end
    else -- New node
        if diff.parentId then
            self:trackParent(id, diff.parentId)
            self:trackTags(id, diff.parentId, diff.tags)
        end
    end
end


--
-- Parent / child
--

function NodeManager:setParent(node, newParentId)
    local oldParentId = node.parentId
    if oldParentId ~= newParentId then
        local id = node.id

        -- Untrack old parent
        if oldParentId then
            for tag in pairs(node.tags) do
                self:untrackTag(id, oldParentId, tag)
            end
            self:untrackParent(id, oldParentId)
            node.parentId = nil
        end

        -- Track new parent
        if newParentId then
            self:trackParent(id, newParentId)
            for tag in pairs(node.tags) do
                self:trackTag(id, newParentId, tag)
            end
            node.parentId = newParentId
        end
    end
end

function NodeManager:hasChildren(idOrNode)
    local id = type(idOrNode) == 'string' and idOrNode or idOrNode.id
    local childIndex = self.parentChildIndex[id]
    return childIndex and next(childIndex) ~= nil
end

function NodeManager:forEachChild(idOrNode, func)
    local id = type(idOrNode) == 'string' and idOrNode or idOrNode.id
    local childIndex = self.parentChildIndex[id]
    if childIndex then
        for id in pairs(childIndex) do
            if func(id, self:getById(id)) == false then
                return
            end
        end
    end
end

function NodeManager:getChildWithId(idOrNode, childId)
    local id = type(idOrNode) == 'string' and idOrNode or idOrNode.id
    local childIndex = self.parentChildIndex[id]
    if childIndex then
        if childIndex[childId] then
            return self:getById(childId)
        end
    end
    return nil
end

function NodeManager:forEachChildWithTag(idOrNode, tag, func)
    local id = type(idOrNode) == 'string' and idOrNode or idOrNode.id
    local tagChildIndex = self.parentTagChildIndex[id]
    if tagChildIndex then
        local childIndex = tagChildIndex[tag]
        if childIndex then
            for id in pairs(childIndex) do
                if func(id, self:getById(id)) == false then
                    return
                end
            end
        end
    end
end


--
-- Tags
--

function NodeManager:addTag(node, tag)
    local parentId = node.parentId
    if parentId then
        if not node.tags[tag] then
            self:trackTag(node.id, node.parentId, tag)
            node.tags[tag] = true
        end
    end
end

function NodeManager:removeTag(node, tag)
    local parentId = node.parentId
    if parentId then
        if node.tags[tag] then
            self:untrackTag(node.id, node.parentId, tag)
            node.tags[tag] = nil
        end
    end
end

function NodeManager:setTags(node, newTags)
    local id, parentId = node.id, node.parentId
    for tag in pairs(node.tags) do -- Removed tags
        if not newTags[tag] then
            self:untrackTag(id, parentId, tag)
            node.tags[tag] = nil
        end
    end
    for tag in pairs(newTags) do -- Added tags
        if not node.tags[tag] then
            self:trackTag(id, parentId, tag)
            node.tags[tag] = true
        end
    end
end


--
-- Locking / controlling
--

function NodeManager:lock(id, clientId)
    assert(self.isServer, 'only servers can `:lock`')
    local lock = self.locks[id]
    if not lock then -- Not locked, acquire
        self.locks[id] = clientId
        return true
    end
    return lock == clientId
end

function NodeManager:unlock(id, clientId)
    assert(self.isServer, 'only servers can `:unlock`')
    if self.locks[id] == clientId then
        self.locks[id] = nil
    end
end

function NodeManager:canLock(id, clientId)
    clientId = clientId or self.clientId
    local lock = self.locks[id]
    return not lock or lock == clientId
end


function NodeManager:control(id)
    assert(self.isClient, "only clients can call `:control`")
    assert(self:canLock(id, self.clientId), "can't acquire lock")
    self.controlled[id] = self.shared[id]
end

function NodeManager:uncontrol(id)
    assert(self.isClient, "only clients can call `:uncontrol`")
    assert(self:canLock(id, self.clientId), "can't acquire lock")
    self.controlled[id] = nil
end

function NodeManager:hasControl(id)
    assert(self.isClient, "only clients can call `:hasControl`")
    return self.controlled[id] ~= nil
end


--
-- Proxies
--

function NodeManager:getProxy(idOrNode)
    local node = self:resolveIdOrNode(idOrNode)
    local proxy = self.proxies[node.id]
    if not proxy then
        proxy = setmetatable({ __nodeManager = self }, node_types[node.type].proxyMetatable)
        self.proxies[node.id] = proxy
    end
    proxy.__node = node
    return proxy
end


return node_manager