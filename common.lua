cs = require 'https://raw.githubusercontent.com/castle-games/share.lua/623c500de3cbfd544db9e6f2bdcd03b5b7e6f377/cs.lua'

uuid = require 'https://raw.githubusercontent.com/Tieske/uuid/75f84281f4c45838f59fc2c6f893fa20e32389b6/src/uuid.lua'
uuid.seed()


--- CONSTANTS

G = 32              -- Grid unit size

WALK_SPEED = 6 * G

CAMERA_GUTTER = 120

MIN_FONT_SIZE, MAX_FONT_SIZE = 8, 72

NODE_COMMON_DEFAULTS = {
    type = 'image',
    parentId = nil,
    x = 0,
    y = 0,
    rotation = 0,
    depth = 0,
    width = 4 * G,
    height = 4 * G,
}

NODE_TYPE_DEFAULTS = {
    image = {
        url = 'https://github.com/nikki93/edit-world/raw/66e4850578fd46cbb9f3c1db30611981f26906e5/checkerboard.png',
        smoothScaling = true,
        crop = false,
        cropX = 0,
        cropY = 0,
        cropWidth = 32,
        cropHeight = 32,
    },
    text = {
        text = 'type some\ntext here!',
        fontSize = 14,
        color = { r = 0, g = 0, b = 0, a = 1 },
        fontUrl = '',
    },
    group = {
        childrenIds = {},
        rules = {},
    },
}

SETTINGS_DEFAULTS = {
    backgroundColor = { r = 1, g = 0.98, b = 0.98 },
    defaultSmoothScaling = true,
}

RULE_COMMON_DEFAULTS = {
    enabled = true,
    kind = 'think',
    action = 'code',
    description = '',
}

RULE_ACTION_DEFAULTS = {
    code = {
        edited = nil,
        applied = '',
    },
}

RULE_DESCRIPTION_DEFAULTS = {
    code = 'run code',
}

MAX_RULE_DESCRIPTION_LENGTH = 32


--- GRAPHICS UTILS

if love.graphics then
    -- `love.graphics.stacked([arg], func)` calls `func` between `love.graphics.push([arg])` and
    -- `love.graphics.pop()` while being resilient to errors
    function love.graphics.stacked(argOrFunc, funcOrNil)
        love.graphics.push(funcOrNil and argOrFunc)
        local succeeded, err = pcall(funcOrNil or argOrFunc)
        love.graphics.pop()
        if not succeeded then
            error(err, 0)
        end
    end
end


--- COMMON LOGIC

function getRuleDescription(rule)
    return rule.description == '' and RULE_DESCRIPTION_DEFAULTS[rule.action] or rule.description
end

do
    local cache = {}

    local env = setmetatable({
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
        math = { abs = math.abs, acos = math.acos, asin = math.asin,
            atan = math.atan, atan2 = math.atan2, ceil = math.ceil, cos = math.cos,
            cosh = math.cosh, deg = math.deg, exp = math.exp, floor = math.floor,
            fmod = math.fmod, frexp = math.frexp, huge = math.huge,
            ldexp = math.ldexp, log = math.log, log10 = math.log10, max = math.max,
            min = math.min, modf = math.modf, pi = math.pi, pow = math.pow,
            rad = math.rad, random = math.random, sin = math.sin, sinh = math.sinh,
            sqrt = math.sqrt, tan = math.tan, tanh = math.tanh },
        os = { clock = os.clock, difftime = os.difftime, time = os.time },
    }, {
        __newindex = function(t, k)
            error("global variable '" .. k .. "' not allowed!", 2)
        end,
    })

    function compileCode(code, desc)
        local cached = cache[code]
        if not cached then
            cached = {}
            cache[code] = cached
            local chunk, err = load(code, desc, 't', env)
            if chunk then
                cached.func = chunk()
            else
                cached.err = err
            end
        end
        return cached.func, cached.err
    end
end

local getNodeProxy
do
    local nodeProxyIndex = {}


    function nodeProxyIndex:getId()
        return self.node.id
    end

    function nodeProxyIndex:getType()
        return self.node.type
    end

    function nodeProxyIndex:getChildren()
        local node = self.node
        if node.type ~= 'group' then
            return {}
        end
        local children = {}
        local getNodeWithId = self.getNodeWithId
        for childId in pairs(node.group.childrenIds) do
            children[childId] = getNodeProxy(getNodeWithId(childId), getNodeWithId)
        end
        return children
    end

    function nodeProxyIndex:getChild(childId)
        local node = self.node
        if node.type ~= 'group' then
            return nil
        end
        local getNodeWithId = self.getNodeWithId
        if node.group.childrenIds[childId] then
            return getNodeProxy(getNodeWithId(childId), getNodeWithId)
        end
    end


    function nodeProxyIndex:getPosition()
        local node = self.node
        return node.x, node.y
    end

    function nodeProxyIndex:setPosition(x, y)
        assert(type(x) == 'number', '`x` must be a number')
        assert(type(y) == 'number', '`y` must be a number')
        local node = self.node
        node.x, node.y = x, y
    end

    function nodeProxyIndex:translate(x, y)
        assert(type(x) == 'number', '`x` must be a number')
        assert(type(y) == 'number', '`y` must be a number')
        local node = self.node
        node.x, node.y = node.x + x, node.y + y
    end

    function nodeProxyIndex:getX()
        return self.node.x
    end

    function nodeProxyIndex:setX(x)
        assert(type(x) == 'number', '`x` must be a number')
        self.node.x = x
    end

    function nodeProxyIndex:getY()
        return self.node.y
    end

    function nodeProxyIndex:setY(y)
        assert(type(y) == 'number', '`y` must be a number')
        self.node.y = y
    end

    function nodeProxyIndex:getRotation()
        return self.node.rotation
    end

    function nodeProxyIndex:setRotation(rotation)
        assert(type(rotation) == 'number', '`rotation` must be a number')
        self.node.rotation = rotation
    end

    function nodeProxyIndex:rotate(rotation)
        assert(type(rotation) == 'number', '`rotation` must be a number')
        local node = self.node
        node.rotation = node.rotation + rotation
    end

    function nodeProxyIndex:getDepth()
        return self.node.depth
    end

    function nodeProxyIndex:setDepth(depth)
        assert(type(depth) == 'number', '`depth` must be a number')
        self.node.depth = depth
    end

    function nodeProxyIndex:getPosition()
        local node = self.node
        return node.width, node.height
    end

    function nodeProxyIndex:setPosition(width, height)
        assert(type(width) == 'number', '`width` must be a number')
        assert(type(height) == 'number', '`height` must be a number')
        local node = self.node
        node.width, node.height = width, height
    end

    function nodeProxyIndex:getWidth()
        return self.node.width
    end

    function nodeProxyIndex:setWidth(width)
        assert(type(width) == 'number', '`width` must be a number')
        self.node.width = width
    end

    function nodeProxyIndex:getHeight()
        return self.node.height
    end

    function nodeProxyIndex:setHeight(height)
        assert(type(height) == 'number', '`height` must be a number')
        self.node.height = height
    end


    local nodeProxyMeta = {
        __index = nodeProxyIndex,
        __newindex = function(t, k)
            error("setting member '" .. k .. "' of node not allowed", 2)
        end,
     }

    function getNodeProxy(node, getNodeWithId)
        if node == nil then
            return nil
        end
        return setmetatable({
            node = node,
            getNodeWithId = getNodeWithId,
        }, nodeProxyMeta)
    end
end

do
    local cache = {}

    local lastErrPrintTime = {}

    function runThinkRules(node, getNodeWithId)
        local dt = love.timer.getDelta()

        if node.type == 'group' then
            for i = 1, #node.group.rules do
                local rule = node.group.rules[i]
                if rule.enabled and rule.kind == 'think' then
                    if rule.action == 'code' then
                        local err

                        local cached = cache[rule.code.applied]
                        if not cached then
                            cached = {}
                            cache[rule.code.applied] = cached
                            local fullCode = 'return function(node, dt)\n' .. rule.code.applied .. '\nend'
                            cached.compiled, err = compileCode(fullCode, getRuleDescription(rule))
                        end
                        local compiled = cached.compiled
                        if compiled then
                            local succeeded
                            succeeded, err = pcall(compiled, getNodeProxy(node, getNodeWithId), dt)
                        end

                        if err then
                            local time = love.timer.getTime()
                            if not lastErrPrintTime[err] or time - lastErrPrintTime[err] > 1 then
                                print(err)
                                lastErrPrintTime[err] = time
                            end
                        end
                    end
                end
            end
        end
    end
end