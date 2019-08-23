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
    name = '',
    x = 0,
    y = 0,
    rotation = 0,
    depth = 1,
    width = 4 * G,
    height = 4 * G,
    portalEnabled = false,
    portalTargetName = '',
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
    },
}


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

function addToGroup(parent, child)
    if child.parentId ~= parent.id and parent.type == 'group' then
        child.parentId = parent.id
        parent.group.childrenIds[child.id] = true
    end
end

function removeFromGroup(parent, child)
    if child.parentId == parent.id then
        child.parentId = nil
        parent.group.childrenIds[child.id] = nil
    end
end