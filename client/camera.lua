local client = require 'client.init'


local camera = {}


local GUTTER = 5


local x, y = 0, 0
local width, height = 25, 14.0625
local transform = love.math.newTransform()


local home = client.home


function camera.getTransform()
    return transform
end

function camera.getBaseLineWidth()
    return width / love.graphics.getWidth()
end


function camera.update(dt)
    -- Respect window aspect ratio
    local windowW, windowH = love.graphics.getDimensions()
    height = width * windowH / windowW

    -- Follow player
    local player = home.player
    if player then
        local gutter = GUTTER * width / love.graphics.getWidth()
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