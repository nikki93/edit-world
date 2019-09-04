local selections = require 'client.selections'
local locals = require 'client.locals'
local graphics_utils = require 'client.graphics_utils'
local space = require 'client.space'
local camera = require 'client.camera'


local mode_none = {}


function mode_none.newNode()
    selections.deselectAll()
    local newNode = locals.nodeManager:new({ isControlled = true })
    selections.attemptPrimarySelect(newNode.id)
end

function mode_none.deleteNodes()
end

function mode_none.cloneNodes()
end


function mode_none.clickSelect(screenMouseX, screenMouseY)
    local worldMouseX, worldMouseY = camera.getTransform():inverseTransformPoint(screenMouseX, screenMouseY)

    -- Collect hits
    local hits = {}
    locals.nodeManager:forEach(function(id, node)
        local localMouseX, localMouseY = space.getWorldSpace(node).transform:inverseTransformPoint(worldMouseX, worldMouseY)
        if math.abs(localMouseX) <= 0.5 * node.width and math.abs(localMouseY) <= 0.5 * node.height then
            table.insert(hits, node)
        end
    end)
    table.sort(hits, space.compareDepth)

    -- Pick next in order if something's already selected, else pick first
    local pick
    for i = #hits, 1, -1 do
        local j = i == 1 and #hits or i - 1
        if selections.isSelected(hits[i].id, 'primary', 'conflicting') then
            pick = hits[j]
        end
    end
    pick = pick or hits[#hits]

    -- Select it, or if nothing, deselect all
    if pick then
        selections.attemptPrimarySelect(pick.id)
    else
        selections.deselectAll()
    end
end

function mode_none.mousepressed(x, y, button)
    if button == 1 then
        mode_none.clickSelect(x, y)
    end
end


return mode_none