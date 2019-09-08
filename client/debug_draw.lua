local debug_draw = {}


local worldSpace = {}


function debug_draw.addWorldSpace(func)
    table.insert(worldSpace, func)
end


function debug_draw.flushWorldSpace()
    for _, func in ipairs(worldSpace) do
        func()
    end
    worldSpace = {}
end


return debug_draw