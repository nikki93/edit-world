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
    selections.forEach('primary', function(id)
        locals.nodeManager:trackDeletion(id)
    end)
end

function mode_none.cloneNodes()
    selections.forEach('primary', function(id)
        local newNode = locals.nodeManager:clone(id, { isControlled = true })
        newNode.x, newNode.y = newNode.x + 1, newNode.y + 1
        selections.deselect(id, 'primary')
        selections.attemptPrimarySelect(newNode.id)
    end)
end


function mode_none.clickSelect(screenMouseX, screenMouseY)
    -- Deselect everything first, unless multi-selecting
    if not (love.keyboard.isDown('lctrl') or love.keyboard.isDown('rctrl')) then
        selections.deselectAll()
    end

    -- Collect hits
    local hits = {}
    local worldMouseX, worldMouseY = camera.getTransform():inverseTransformPoint(screenMouseX, screenMouseY)
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
    if pick then
        selections.attemptPrimarySelect(pick.id)
    end
end

function mode_none.mousepressed(x, y, button)
    if button == 1 then
        mode_none.clickSelect(x, y)
    end
end


return mode_none