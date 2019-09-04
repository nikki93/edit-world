local client = require 'client.init'


local camera = {}


local GUTTER = 5


local x, y = 0, 0
local width, height = 25, 14.0625


local home = client.home


function camera.applyTransform()
    local windowW, windowH = love.graphics.getDimensions()
    love.graphics.scale(windowW / width, windowH / height)
    love.graphics.translate(-x + 0.5 * width, -y + 0.5 * height)
end


function camera.update(dt)
    local player = home.player
    if player then
        local gutter = GUTTER * width / love.graphics.getWidth()
        if home.x - 0.5 < x - 0.5 * width + gutter then
            x = home.x - 0.5 + 0.5 * width - gutter
        end
        if home.x + 0.5 > x + 0.5 * width - gutter then
            x = home.x + 0.5 - 0.5 * width + gutter
        end
        if home.y - 0.5 < y - 0.5 * height + gutter then
            y = home.y - 0.5 + 0.5 * height - gutter
        end
        if home.y + 0.5 > y + 0.5 * height - gutter then
            y = home.y + 0.5 - 0.5 * height + gutter
        end
    end
end


return camera