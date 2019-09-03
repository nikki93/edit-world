local table_utils = require 'common.table_utils'
local node_types = require 'common.node_types'
local libs = require 'common.libs'


local node_manager = {}


local DELETION_WAIT = 1
local DELETION_DELETE = 2
local DELETION_DELETED = 3


local NodeManager = {}
local NodeManagerMetatable = {
    __index = NodeManager,
}

function node_manager.new(opts)
    local self = setmetatable({}, NodeManagerMetatable)

    if opts.isServer then
        self.isServer = true
        self.isClient = false

        self.shared = assert(opts.shared)
        self.locks = assert(opts.locks)
    else
        self.isServer = false
        self.isClient = true

        self.shared = assert(opts.shared)
        self.controlled = assert(opts.controlled)
    end

    self.proxies = {}                   -- `node.id` -> `node_types[node.type]` instance with `.node` == `node`
    self.parentChildIndex = {}          -- `parent.id` -> `child.id` -> `true` for all `child.parentId == parent.id`
    self.parentTagChildIndex = {}       -- `parent.id` -> `tag` -> `child.id` -> `true` for all `child.parentId == parent.id and child.tags[tag]`
    self.deletions = {}                 -- `node.id` -> (`DELETION_WAIT` or `DELETION_DELETE`)

    return self
end


function NodeManager:new(opts)
    local newId = uuid()

    local newNode = table_utils.clone(node_types.base.DEFAULTS)
    newNode.id = newId
    newNode.rngState = love.math.newRandomGenerator(love.math.random()):getState()
    newNode[newNode.type] = node_types[newNode.type].DEFAULTS

    if self.isServer then
        self.shared[id] = newNode
    else
        if opts.isControlled then
            self.controlled[id] = newNode
        else
            self.shared[id] = newNode
        end
    end

    return newNode
end

function NodeManager:clone(node)
    local newId = uuid()

    local newNode = table_utils.clone(node)
    newNode.id = newId
    newNode.rngState = love.math.newRandomGenerator(love.math.random()):getState()
    if newNode.parentId then
        self:trackParent(newNode)
    end

    return newNode
end


function NodeManager:trackDeletion(id, deletion)
    self.deletions[id] = deletion
end

function NodeManager:delete(node)
    node.deletion = DELETION_DELETED

    local id = node.id

    local parentId = node.parentId
    if parentId then
        for tag in pairs(node.tags) do
            self:untrackTag(nodeId, parentId, tag)
        end
        self:untrackParent(nodeId, parentId)
    end

    self.proxies[id] = nil
    self.deletions[id] = nil
    self.locks[id] = nil

    if self.isServer then
        self.shared[id] = nil
    else
        self.shared[id] = nil
        self.controlled[id] = nil
    end
end

function NodeManager:processDeletions()
    for id, deletion in pairs(self.deletions) do
        local node = self:getNodeById(id)
        if node then
            if deletion == DELETION_WAIT then
                node.deletion = DELETION_DELETE
                self:trackDeletion(id, node.deletion)
            elseif deletion == DELETION_DELETE then
                self:delete(node)
            end
        else
            self.deletions[id] = nil
        end
    end
end


function NodeManager:getNodeById(id)
    if self.isServer then
        return self.shared[id]
    else
        return self.controlled[id] or self.shared[id]
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
    local node = self:getNodeById(id)
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
            if rootExact or diff.__exact or diff.tags.__exact then -- Exact new tags
                for tag in pairs(diff.tags) do
                    if tag ~= '__exact' then
                        self:trackTag(id, newParentId, tag)
                    end
                end
            else -- Diff'd new tags
                for tag in pairs(node.tags) do 
                    if diff.tags[tag] ~= libs.state.DIFF_NIL then -- Old tag and not removed in new
                        self:trackTag(id, newParentId, tag)
                    end
                end
                for tag in pairs(diff.tags) do
                    if not node.tags[tag] then -- New tag
                        self:trackTag(id, newParentId, tag)
                    end
                end
            end
        else -- Parent didn't change, just track tag changes
            local parentId = newParentId
            if rootExact or diff.__exact or diff.tags.__exact then -- Exact new tags
                for tag in pairs(node.tags) do
                    if not diff.tags[tag] then -- Old tag and removed in new
                        self:untrackTag(nodeId, parentId, tag)
                    end
                end
                for tag in pairs(diff.tags) do
                    if tag ~= '__exact' and not node.tags[tag] then -- New tag
                        self:trackTag(nodeId, parentId, tag)
                    end
                end
            else
                for tag, v in pairs(diff.tags) do
                    if v == libs.state.DIFF_NIL then -- Tag removed
                        self:untrackTag(nodeId, parentId, tag)
                    else -- Tag added
                        self:trackTag(nodeId, parentId, tag)
                    end
                end
            end
        end

        if diff.deletion then
            self:trackDeletion(id, deletion)
        end
    else -- New node
        if dif.parentId then
            self:trackParent(id, diff.parentId)
            self:trackTags(id, diff.parentId, diff.tags)
        end

        if diff.deletion then
            self:trackDeletion(id, diff.deletion)
        end
    end
end


function NodeManager:runThinkRules(dt)
end


function NodeManager:lock(id, clientId)
    local lock = self.locks[id]
    if lock == nil then -- Not locked, acquire
        self.locks[id] = clientId
        return true
    end
    return lock == clientId
end

function NodeManager:unlock(id, clientId)
    if self.locks[id] == clientId then
        self.locks[id] = nil
    end
end


return node_manager