local code_loader = {}


local sandboxEnv = {
    print = print,
    ipairs = ipairs,
    next = next,
    pairs = pairs,
    pcall = pcall,
    tonumber = tonumber,
    tostring = tostring,
    type = type,
    unpack = unpack,
    coroutine = { create = coroutine.create, resume = coroutine.resume,
        running = coroutine.running, status = coroutine.status,
        wrap = coroutine.wrap },
    string = { byte = string.byte, char = string.char, find = string.find,
        format = string.format, gmatch = string.gmatch, gsub = string.gsub,
        len = string.len, lower = string.lower, match = string.match,
        rep = string.rep, reverse = string.reverse, sub = string.sub,
        upper = string.upper },
    table = { insert = table.insert, maxn = table.maxn, remove = table.remove,
        sort = table.sort },
    math = {
        -- Omit `math.random` in favor of `:random()` on nodes
        abs = math.abs, acos = math.acos, asin = math.asin,
        atan = math.atan, atan2 = math.atan2, ceil = math.ceil, cos = math.cos,
        cosh = math.cosh, deg = math.deg, exp = math.exp, floor = math.floor,
        fmod = math.fmod, frexp = math.frexp, huge = math.huge,
        ldexp = math.ldexp, log = math.log, log10 = math.log10, max = math.max,
        min = math.min, modf = math.modf, pi = math.pi, pow = math.pow,
        rad = math.rad, sin = math.sin, sinh = math.sinh,
        sqrt = math.sqrt, tan = math.tan, tanh = math.tanh,
    },
    love = {
        math = {
            -- Omit rng functions in favor of `:random()`, `:randomNormal()` on nodes
            compress = love.math.compress,
            decompress = love.math.decompress,
            gammaToLinear = love.math.gammaToLinear,
            isConvex = love.math.isConvex,
            linearToGamma = love.math.linearToGamma,
            newBezierCurve = love.math.newBezierCurve,
            newTransform = love.math.newTransform,
            noise = love.math.noise,
            triangulate = love.math.triangulate,
        },
    },
}

local function freeze(t, prefix)
    if type(t) == 'table' then
        for k, v in pairs(t) do
            t[k] = freeze(v, prefix .. k .. '.')
        end
        setmetatable(t, {
            __index = function(_, k)
                error("no such variable `" .. prefix .. k .. "`", 2)
            end
        })
        t = setmetatable({}, {
            __index = t,
            __newindex = function(_, k)
                error("no such variable `" .. prefix .. k .. "`" .. (prefix == '' and " -- must be defined using `local`" or ''), 2)
            end,
        })
    end
    return t
end
sandboxEnv = freeze(sandboxEnv, '')


local holders = setmetatable({}, { __mode = 'v' })

function code_loader.compile(code, description)
    local holder = holders[code]
    if not holder then
        holder = {}
        holders[code] = holder
        local chunk, err = load('return function(node, params)\n' .. code .. '\nend', description, 't', sandboxEnv)
        if chunk then
            holder.compiled = chunk()
        else
            holder.err = err
        end
    end
    return holder
end


return code_loader