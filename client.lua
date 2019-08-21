require 'common'


--- CLIENT

local client = cs.client

if USE_CASTLE_CONFIG then
    client.useCastleConfig()
else
    client.enabled = true
    client.start('127.0.0.1:22122')
end

local share = client.share
local home = client.home


--- UTIL

local imageFromUrl
do
    local cache = {}
    function imageFromUrl(url)
        local cached = cache[url]
        if not cached then
            cached = {}
            cache[url] = cached
            network.async(function()
                cached.image = love.graphics.newImage(url)
            end)
        end
        return cached.image
    end
end


--- LOAD

local cameraX, cameraY

function client.load()
    cameraX, cameraY = -0.5 * love.graphics.getWidth(), -0.5 * love.graphics.getHeight()
end


--- CONNECT

function client.connect()
    do -- Walk
        home.me = castle.user.getMe()
    end
end


--- DRAW

function client.draw()
    love.graphics.clear(1, 0.98, 0.98)

    if client.connected then
        love.graphics.stacked('all', function() -- Camera transform
            love.graphics.translate(-cameraX, -cameraY)

            do -- Players
                for clientId, player in pairs(share.players) do
                    local x, y = player.x, player.y

                    if clientId == client.id and home.x and home.y then
                        x, y = home.x, home.y
                    end

                    if player.me then
                        local photo = imageFromUrl(player.me.photoUrl)
                        if photo then
                            love.graphics.draw(photo, x, y, 0, G / photo:getWidth(), G / photo:getHeight())
                        end
                    end
                end
            end
        end)

        love.graphics.stacked('all', function()
            love.graphics.setColor(0, 0, 0)
            love.graphics.print('fps: ' .. love.timer.getFPS(), 20, 20)
        end)
    else -- Not connected
        love.graphics.print('connecting...', 20, 20)
    end
end


--- UPDATE

function client.update(dt)
    if client.connected then
        do -- Player motion
            local player = share.players[client.id]

            if not (home.x and home.y) then
                home.x, home.y = player.x, player.y
            end

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

            home.x, home.y = home.x + vx * dt, home.y + vy * dt
        end
    end
end


--- CHANGING

function client.changing(diff)
    if diff.time and share.time then -- Make sure time only goes forward
        diff.time = math.max(share.time, diff.time)
    end
end


--- KEYBOARD

function client.keypressed(key)
end

function client.keyreleased(key)
end