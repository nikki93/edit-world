local locals = require 'client.locals'


local space = {}


local worldSpaceCache

local rootSpace = {
    transform = love.math.newTransform(),
    depth = 0,
}


function space.getWorldSpace(node)
    if node == nil then
        return rootSpace
    end

    local cached = worldSpaceCache[node]
    if not cached then
        cached = {}
        worldSpaceCache[node] = cached

        local parentWorldSpace = space.getParentWorldSpace(node)
        if not parentWorldSpace.transform then -- Cycle?
            parentWorldSpace = rootSpace
        end
        cached.transform = parentWorldSpace.transform:clone():translate(node.x, node.y):rotate(node.rotation)
        cached.depth = parentWorldSpace.depth + node.depth
    end
    return cached
end

function space.getParentWorldSpace(node)
    local parent = locals.nodeManager:getById(node.parentId)
    if parent and parent.deleting then
        parent = nil
    end
    return space.getWorldSpace(parent)
end

function space.clearWorldSpaceCache()
    worldSpaceCache = setmetatable({}, { __mode = 'k' })
end
space.clearWorldSpaceCache()


function space.compareDepth(node1, node2)
    local depth1, depth2 = space.getWorldSpace(node1).depth, space.getWorldSpace(node2).depth
    if depth1 < depth2 then
        return true
    end
    if depth1 > depth2 then
        return false
    end
    return node1.id < node2.id
end


return space