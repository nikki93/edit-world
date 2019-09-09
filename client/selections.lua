local locals = require 'client.locals'
local table_utils = require 'common.table_utils'


local selections = {}


selections.primary = {}
selections.secondary = {}
selections.conflicting = {}

local selectionTypes = { 'primary', 'secondary', 'conflicting' }


function selections.isAnySelected(selectionType, ...)
    if selectionType == nil then
        return false
    end
    return next(selections[selectionType]) ~= nil or selections.isAnySelected(...)
end

function selections.numSelections(...)
    local n = 0
    local nArgs = select('#', ...)
    for i = 1, nArgs do
        for id in pairs(selections[select(i, ...)]) do
            n = n + 1
        end
    end
    return n
end

function selections.isSelected(id, selectionType, ...)
    if selectionType == nil then
        return false
    end
    return selections[selectionType][id] or selections.isSelected(id, ...)
end

function selections.attemptPrimarySelect(id, conflictingSelectIfFail)
    if locals.nodeManager:canLock(id) then
        if not locals.nodeManager:hasControl(id) then
            locals.nodeManager:control(id)
        end
        selections.primary[id] = true
    elseif conflictingSelectIfFail ~= false then
        selections.conflicting[id] = true
    end
end

function selections.deselect(id, selectionType, ...)
    if selectionType == nil then
        return
    end
    selections[selectionType][id] = nil
    selections.deselect(id, ...)
end

function selections.deselectAll()
    for id in pairs(selections.primary) do
        locals.nodeManager:uncontrol(id)
    end
    for _, selectionType in ipairs(selectionTypes) do
        selections[selectionType] = {}
    end
end

function selections.forEach(...)
    local nArgs = select('#', ...)
    assert(nArgs >= 2, '`selections.forEach` needs at least 2 arguments')
    local func = select(nArgs, ...)
    for i = 1, nArgs - 1 do
        local selectionType = select(i, ...)
        for id in pairs(table_utils.clone(selections[selectionType])) do
            local node = locals.nodeManager:getById(id)
            if node then
                if func(id, node) == false then
                    return
                end
            end
        end
    end
end


function selections.clearDeletedSelections()
    for _, selectionType in ipairs(selectionTypes) do
        for id in pairs(selections[selectionType]) do
            if not locals.nodeManager:getById(id) then
                selections[selectionType][id] = nil
            end
        end
    end
end


return selections