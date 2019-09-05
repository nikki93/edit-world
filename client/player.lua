local table_utils = require 'common.table_utils'
local node_image = require 'common.node_image'


local player = {}


local WALK_SPEED = 6


function player.init(p)
    p = table_utils.clone(p)

    p.me = castle.user.getMe()

    return p
end

function player.draw(p)
    local image = node_image.imageFromUrl((p.me and p.me.photoUrl) or '')
    local scaleX, scaleY = 1 / image:getWidth(), 1 / image:getHeight()
    love.graphics.draw(image, p.x - 0.5, p.y - 0.5, 0, scaleX, scaleY)
end

function player.update(p, dt)
    local vx, vy = 0, 0
    if love.keyboard.isDown('a') then
        vx = vx - WALK_SPEED
    end
    if love.keyboard.isDown('d') then
        vx = vx + WALK_SPEED
    end
    if love.keyboard.isDown('w') then
        vy = vy - WALK_SPEED
    end
    if love.keyboard.isDown('s') then
        vy = vy + WALK_SPEED
    end
    p.x, p.y = p.x + vx * dt, p.y + vy * dt
end


return player