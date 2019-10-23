local table_utils = require 'common.table_utils'
local resource_loader = require 'common.resource_loader'


local player = {}


local WALK_SPEED = 6


function player.init(p)
    p = table_utils.clone(p)

    p.me = castle.user.getMe()

    return p
end

local imageHolders = {}

function player.draw(p)
    local imageUrl = (p.me and p.me.photoUrl) or ''
    local imageHolder = resource_loader.loadImage(imageUrl)
    imageHolders[imageUrl] = imageHolder
    local image = imageHolder.image

    local scaleX, scaleY = 1 / image:getWidth(), 1 / image:getHeight()
    love.graphics.draw(image, p.x - 0.5, p.y - 0.5, 0, scaleX, scaleY)
end

function player.update(p, dt)
    local vx, vy = 0, 0
    if love.keyboard.isDown('a') or love.keyboard.isDown('left') then
        vx = vx - WALK_SPEED
    end
    if love.keyboard.isDown('d') or love.keyboard.isDown('right') then
        vx = vx + WALK_SPEED
    end
    if love.keyboard.isDown('w') or love.keyboard.isDown('up') then
        vy = vy - WALK_SPEED
    end
    if love.keyboard.isDown('s') or love.keyboard.isDown('down') then
        vy = vy + WALK_SPEED
    end
    p.x, p.y = p.x + vx * dt, p.y + vy * dt
end


return player