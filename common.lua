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
    x = 0,
    y = 0,
    rotation = 0,
    depth = 0,
    width = 4 * G,
    height = 4 * G,
    parentId = nil,
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
    event = 'update',
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
        string = string,
        math = math,
    }, {
        __newindex = function(t, k)
            error("global variable '" .. k .. "' not allowed!")
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

do
    local cache = {}

    local lastErrPrintTime = {}

    function runUpdateRules(node, dt)
        if node.type == 'group' then
            for i = 1, #node.group.rules do
                local rule = node.group.rules[i]
                if rule.event == 'update' then
                    if rule.action == 'code' then
                        local err

                        local cached = cache[rule.code.applied]
                        if not cached then
                            cached = {}
                            cache[rule.code.applied] = cached
                            local fullCode = 'return function(self, dt)\n' .. rule.code.applied .. '\nend'
                            cached.compiled, err = compileCode(fullCode, getRuleDescription(rule))
                        end
                        local compiled = cached.compiled
                        if compiled then
                            local succeeded
                            succeeded, err = pcall(compiled, node, dt)
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