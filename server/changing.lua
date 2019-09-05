local server = require 'server.init'
local locals = require 'server.locals'
local lib = require 'common.lib'
local table_utils = require 'common.table_utils'


local share = server.share
local homes = server.homes


function server.changing(clientId, homeDiff)
    if homeDiff.nodes and homeDiff.nodes.controlled then
        local shared = share.nodes.shared
        local home = homes[clientId]
        local controlled = home and home.nodes and home.nodes.controlled or {}
        local controlledDiff = homeDiff.nodes.controlled
        local rootExact = homeDiff.__exact or homeDiff.nodes.__exact or controlledDiff.__exact
        if rootExact then
            for nodeId in pairs(controlled) do
                if not controlledDiff[nodeId] then -- Client released control
                    locals.nodeManager:unlock(nodeId, clientId)
                end
            end
        end
        for nodeId, nodeDiff in pairs(controlledDiff) do
            if nodeId ~= '__exact' then
                if locals.nodeManager:canLock(nodeId, clientId) and nodeDiff == lib.state.DIFF_NIL then
                    -- Don't needlessly lock and unlock if client is immediately releasing control
                    locals.nodeManager:unlock(nodeId, clientId)
                elseif locals.nodeManager:lock(nodeId, clientId) then
                    assert(nodeDiff ~= lib.state.DIFF_NIL, 'internal error: client releasing control not caught in first branch')
                    local alreadyDeleting = controlled[nodeId] and controlled[nodeId].deleting
                    if alreadyDeleting or nodeDiff.deleting then -- Client requested a delete
                        local node = locals.nodeManager:getById(nodeId)
                        if node then
                            locals.nodeManager:actuallyDelete(node)
                        end
                    else -- Client made a controlled edit to this node
                        locals.nodeManager:trackDiff(nodeId, nodeDiff, rootExact)
                        if rootExact then
                            shared[nodeId] = nodeDiff
                        else
                            shared[nodeId] = table_utils.applyDiff(shared[nodeId], nodeDiff)
                        end
                    end
                end
            end
        end
    end
end