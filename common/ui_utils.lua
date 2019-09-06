local ui = castle.ui


local ui_utils = {}


function ui_utils.row(id, ...)
    local nArgs = select('#', ...)
    local args = { ... }
    ui.box(id, { flexDirection = 'row', alignItems = 'center' }, function()
        for i = 1, nArgs do
            ui.box(tostring(i), { flex = 1 }, args[i])
            if i < nArgs then
                ui.box('space', { width = 20 }, function() end)
            end
        end
    end)
end


return ui_utils