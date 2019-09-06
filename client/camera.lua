local client = require 'client.init'


local camera = {}


local DEFAULT_WIDTH = 25
local ZOOM_BASE = 2
local MIN_ZOOM_EXPONENT, MAX_ZOOM_EXPONENT = -1, 3
local GUTTER = 4


local x, y = 0, 0
local zoomExponent = 0
local width, height = DEFAULT_WIDTH, DEFAULT_WIDTH * love.graphics.getHeight() / love.graphics.getWidth()
local transform = love.math.newTransform()


local home = client.home


function camera.getTransform()
    return transform
end


local function zoomBy(by)
    zoomExponent = math.min(math.max(MIN_ZOOM_EXPONENT, zoomExponent + by), MAX_ZOOM_EXPONENT)
    width = DEFAULT_WIDTH * math.pow(ZOOM_BASE, zoomExponent)
end

function camera.zoomIn()
    zoomBy(-1)
end

function camera.zoomOut()
    zoomBy(1)
end

function camera.getZoomFactor()
    return width / DEFAULT_WIDTH
end


function camera.update(dt)
    -- Respect window aspect ratio
    local windowW, windowH = love.graphics.getDimensions()
    height = width * windowH / windowW

    -- Follow player
    local player = home.player
    if player then
        local gutter = GUTTER * width / 25
        if player.x - 0.5 < x - 0.5 * width + gutter then
            x = player.x - 0.5 + 0.5 * width - gutter
        end
        if player.x + 0.5 > x + 0.5 * width - gutter then
            x = player.x + 0.5 - 0.5 * width + gutter
        end
        if player.y - 0.5 < y - 0.5 * height + gutter then
            y = player.y - 0.5 + 0.5 * height - gutter
        end
        if player.y + 0.5 > y + 0.5 * height - gutter then
            y = player.y + 0.5 - 0.5 * height + gutter
        end
    end

    -- Update the transform
    transform:reset()
    transform:scale(windowW / width)
    transform:translate(-x + 0.5 * width, -y + 0.5 * height)
end


return camera