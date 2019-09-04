local locals = require 'client.locals'


local selections = {}


selections.primary = {}
selections.secondary = {}
selections.conflicting = {}


function selections.primarySelect(id)
    if not locals.nodeManager:hasControl(id) then
        locals.nodeManager:control(id)
    end
    selections.primary[id] = true
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