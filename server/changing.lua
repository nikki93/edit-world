local server = require 'server.init'
local locals = require 'server.locals'
local libs = require 'common.libs'
local table_utils = require 'common.table_utils'


local share = server.share
local homes = server.homes


function server.changing(clientId, homeDiff)
    if homeDiff.controlled then
        local rootExact = homeDiff.__exact or homeDiff.controlled.__exact
        if rootExact then
            for nodeId in pairs(homes[clientId].controlled or {}) do
                if not homeDiff.controlled[nodeId] then -- Client released control
                    locals.nodeManager:unlock(nodeId, clientId)
                end
            end
        end
        for nodeId, nodeDiff in pairs(homeDiff.controlled) do
            if nodeId ~= '__exact' then
                if locals.nodeManager:lock(nodeId, clientId) then
                    if nodeDiff ~= libs.state.DIFF_NIL then -- Track and apply a controlled change
                        locals.nodeManager:trackDiff(nodeId, nodeDiff, rootExact)
                        if rootExact then
                            share.nodes[nodeId] = nodeDiff
                        else
                            share.nodes[nodeId] = table_utils.applyDiff(share.nodes[nodeId], nodeDiff)
                        end
                    else -- Client released control
                        locals.nodeManager:unlock(nodeId, clientId)
                    end
                end
            end
        end
    end
end