local client = require 'client.init'
local locals = require 'client.locals'
local lib = require 'common.lib'


function client.changing(shareDiff)
    if shareDiff.nodes and shareDiff.nodes.shared then
        local sharedDiff = shareDiff.nodes.shared
        local rootExact = shareDiff.__exact or shareDiff.nodes.__exact or sharedDiff.__exact
        for nodeId, nodeDiff in pairs(sharedDiff) do
            if nodeId ~= '__exact' then
                if nodeDiff ~= lib.state.DIFF_NIL then -- Track a shared change
                    locals.nodeManager:trackDiff(nodeId, nodeDiff, rootExact)
                else -- Server deleted this node
                    local node = locals.nodeManager:getById(nodeId)
                    if node then
                        locals.nodeManager:delete(node)
                    end
                end
            end
        end
    end
end