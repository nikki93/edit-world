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

        self.pendingDeletions = {}      -- `node.id` -> `true` for nodes we're waiting on the server to delete for us
    end

    self.proxies = {}                   -- `node.id` -> rule-facing proxy for that node
    self.parentChildIndex = {}          -- `parent.id` -> `child.id` -> `true` for all `child.parentId == parent.id`
    self.parentTagChildIndex = {}       -- `parent.id` -> `tag` -> `child.id` -> `true` for all `child.parentId == parent.id and child.tags[tag]`

    return self
end


function NodeManager:new(opts)
    local newNodeData
    if opts.initialData then
        newNodeData = table_utils.clone(opts.initialData)
    else
        newNodeData = table_utils.clone(node_types.base.DEFAULTS)
        newNodeData[newNodeData.type] = table_utils.clone(node_types[newNodeData.type].DEFAULTS)
    end
    newNodeData.id = lib.uuid()
    newNodeData.rngState = love.math.newRandomGenerator(love.math.random()):getState()

    -- TODO(nikki): Track if has `.parentId`

    if self.isClient and opts.isControlled then
        self.controlled[newNodeData.id] = newNodeData
        return self.controlled[newNodeData.id]
    else
        self.shared[newNodeData.id] = newNodeData
        return self.shared[newNodeData.id]
    end
end

function NodeManager:clone(idOrNode, opts)
    local node = self:resolveIdOrNode(idOrNode)
    opts = table_utils.clone(opts)
    opts.initialData = node
    return self:new(opts)
end


function NodeManager:actuallyDelete(node)
    local id = node.id

    local parentId = node.parentId
    if parentId then
        for tag in pairs(node.tags) do
            self:untrackTag(id, parentId, tag)
        end
        self:untrackParent(id, parentId)
    end

    self.proxies[id] = nil
    self.locks[id] = nil

    if self.isClient then
        self.pendingDeletions[id] = nil
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
        self.pendingDeletions[node.id] = true
    end
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


function NodeManager:resolveIdOrNode(idOrNode)
    if type(idOrNode) == 'string' then
        return self:getById(idOrNode)
    else
        return idOrNode
    end
end

function NodeManager:getById(id)
    if id == nil then
        return nil
    end
    if self.isServer then
        return self.shared[id]
    else
        return self.controlled[id] or self.shared[id]
    end
end

function NodeManager:forEach(func)
    if self.isServer then
        for id, node in pairs(self.shared) do
            func(id, node)
        end
    else
        for id, node in pairs(self.shared) do
            if not self.controlled[id] then
                func(id, node)
            end
        end
        for id, node in pairs(self.controlled) do
            func(id, node)
        end
    end
end


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
    else -- New node
        if diff.parentId then
            self:trackParent(id, diff.parentId)
            self:trackTags(id, diff.parentId, diff.tags)
        end
    end
end


function NodeManager:runThinkRules(dt)
end


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


return node_manager