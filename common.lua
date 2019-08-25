cs = require 'https://raw.githubusercontent.com/castle-games/share.lua/623c500de3cbfd544db9e6f2bdcd03b5b7e6f377/cs.lua'

uuid = require 'https://raw.githubusercontent.com/Tieske/uuid/75f84281f4c45838f59fc2c6f893fa20e32389b6/src/uuid.lua'
uuid.seed()

serpent = require 'https://raw.githubusercontent.com/pkulchenko/serpent/879580fb21933f63eb23ece7d60ba2349a8d2848/src/serpent.lua'


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
        url = 'https://castle.games/static/logo.png',
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
    type = 'code',
    phrase = '',
}

RULE_TYPE_DEFAULTS = {
    code = {
        edited = nil,
        applied = '',
    },
}

RULE_PHRASE_DEFAULTS = {
    code = 'run code',
}

MAX_RULE_PHRASE_LENGTH = 32


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

-- Apply a diff from `:__diff` or `:__flush` to a target `t` that is itself a `state`
function applyDiff(t, diff)
    if diff == nil then return t end
    if diff.__exact then
        diff.__exact = nil
        return diff
    end
    t = (type(t) == 'table' or type(t) == 'userdata') and t or {}
    for k, v in pairs(diff) do
        if type(v) == 'table' then
            local r = applyDiff(t[k], v)
            if r ~= t[k] then
                t[k] = r
            end
        elseif v == DIFF_NIL then
            t[k] = nil
        else
            t[k] = v
        end
    end
    return t
end
 
function getRulePhrase(rule)
    return rule.phrase == '' and RULE_PHRASE_DEFAULTS[rule.type] or rule.phrase
end
