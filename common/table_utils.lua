local lib = require 'common.lib'


local table_utils = {}


function table_utils.clone()
    local typ = type(t)
    if typ == 'nil' or typ == 'boolean' or typ == 'number' or typ == 'string' then
        return t
    elseif typ == 'table' or typ == 'userdata' then
        local u = {}
        for k, v in pairs(t) do
            u[cloneValue(k)] = cloneValue(v)
        end
        return u
    else
        error('clone: bad type')
    end
end

print('DIFF_NIL: ' .. lib.state.DIFF_NIL)
function table_utils.applyDiff(t, diff)
    if diff == nil then return t end
    if diff.__exact then
        diff.__exact = nil
        return diff
    end
    t = (type(t) == 'table' or type(t) == 'userdata') and t or {}
    for k, v in pairs(diff) do
        if type(v) == 'table' then
            local r = table_utils.applyDiff(t[k], v)
            if r ~= t[k] then
                t[k] = r
            end
        elseif v == lib.state.DIFF_NIL then
            t[k] = nil
        else
            t[k] = v
        end
    end
    return t
end


return table_utils