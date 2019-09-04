local locals = require 'client.locals'


local selections = {}


selections.primary = {}
selections.secondary = {}
selections.conflicting = {}


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

function selections.deselectAll()
    selections.primary = {}
    selections.secondary = {}
    selections.conflicting = {}
end


function selections.clearDeletedSelections()
    for _, selectionType in ipairs({ 'primary', 'secondary', 'conflicting' }) do
        for id in pairs(selections[selectionType]) do
            if not locals.nodeManager:getById(id) then
                selections[selectionType][id] = nil
            end
        end
    end
end


return selections