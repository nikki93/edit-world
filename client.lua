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
    do -- Me
        home.me = castle.user.getMe()
    end

    do -- Selected
        home.selected = {}
    end
end


--- DRAW

function client.draw()
    love.graphics.clear(1, 0.98, 0.98)

    if client.connected then
        love.graphics.stacked('all', function() -- Camera transform
            love.graphics.translate(-cameraX, -cameraY)

            do -- Nodes
                local order = {}

                for id, node in pairs(share.nodes) do -- Share, skipping selected
                    if not home.selected[id] then
                        table.insert(order, node)
                    end
                end

                for id, node in pairs(home.selected) do -- Selected
                    table.insert(order, node)
                end

                table.sort(order, function(node1, node2)
                    if node1.depth < node2.depth then
                        return true
                    end
                    if node1.depth > node2.depth then
                        return false
                    end
                    return node1.id < node2.id
                end)

                for _, node in ipairs(order) do
                    if node.type == 'image' then
                        local image = imageFromUrl(node.imageUrl)
                        if image then
                            local width = node.width
                            local height = node.height
                            if height == 'auto' then
                                height = (image:getHeight() / image:getWidth()) * width
                            end
                            love.graphics.draw(image, node.x, node.y, node.rotation, width / image:getWidth(), height / image:getHeight())

                            love.graphics.stacked('all', function()
                                love.graphics.setColor(1, 0, 0)
                                love.graphics.circle('fill', node.x, node.y, 4)
                            end)
                        end
                    end
                end
            end

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


--- UI

local ui = castle.ui

function client.uiupdate()
    if client.connected then
        if ui.button('new node') then
            home.selected = {}
            local id = uuid()
            home.selected[id] = {
                id = id,
                type = 'image',
                x = cameraX + 0.5 * love.graphics.getWidth(),
                y = cameraY + 0.5 * love.graphics.getHeight(),
                rotation = 0,
                depth = 1,
                imageUrl = 'https://castle.games/static/logo.png',
                width = 4 * G,
                height = 'auto',
            }
        end

        ui.markdown('----')

        for id, node in pairs(home.selected) do
            node.type = ui.dropdown('type', node.type, { 'image', 'text' })
            node.x = ui.numberInput('x', node.x)
            node.y = ui.numberInput('y', node.y)
            node.rotation = ui.numberInput('rotation', node.rotation)
            node.depth = ui.numberInput('depth', node.depth)

            if node.type == 'image' then
                node.imageUrl = ui.textInput('url', node.imageUrl)

                node.width = ui.numberInput('width', node.width)
            end
        end
    end
end