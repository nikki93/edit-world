local table_utils = require 'common.table_utils'
local node_types = require 'common.node_types'


local player = {}


local WALK_SPEED = 6


function player.init(p)
    p = table_utils.clone(p)

    p.me = castle.user.getMe()

    p.node = node_types.base.DEFAULTS
    p.node.image = node_types.image.DEFAULTS
    p.node.width, p.node.height = 1, 1
    p.node.image.url = p.me.photoUrl

    return p
end

function player.draw(p)
    local photoUrl = p.me and p.me.photoUrl
    node_types.image.draw(p.node, love.math.newTransform():translate(p.x, p.y))
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