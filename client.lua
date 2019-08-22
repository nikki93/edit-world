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

local function depthLess(node1, node2)
    if node1.depth < node2.depth then
        return true
    end
    if node1.depth > node2.depth then
        return false
    end
    return node1.id < node2.id
end


--- LOAD

local cameraX, cameraY

local theQuad, theTransform

function client.load()
    cameraX, cameraY = -0.5 * love.graphics.getWidth(), -0.5 * love.graphics.getHeight()

    theQuad = love.graphics.newQuad(0, 0, 32, 32, 32, 32)
    theTransform = love.math.newTransform()
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

function client.draw()
    if client.connected then
        do -- Background color
            local bgc = share.backgroundColor
            love.graphics.clear(bgc.r, bgc.g, bgc.b)
        end

        love.graphics.stacked('all', function() -- Camera transform
            love.graphics.translate(-cameraX, -cameraY)

            do -- Nodes
                local order = {}
                do -- Collect order
                    for id, node in pairs(share.nodes) do -- Share, skipping selected
                        if not home.selected[id] then
                            table.insert(order, node)
                        end
                    end

                    for id, node in pairs(home.selected) do -- Selected
                        table.insert(order, node)
                    end

                    table.sort(order, depthLess)
                end

                for _, node in ipairs(order) do -- Draw order
                    if node.type == 'image' then
                        local image = imageFromUrl(node.image.url)
                        if image then
                            -- Don't call `:setFilter` unnecessarily
                            local filter = image:getFilter()
                            if node.image.smoothScaling and filter == 'nearest' then
                                image:setFilter('linear')
                            end
                            if not node.image.smoothScaling and filter == 'linear' then
                                image:setFilter('nearest')
                            end

                            local iw, ih = image:getWidth(), image:getHeight()

                            if node.image.crop then
                                theQuad:setViewport(node.image.cropX, node.image.cropY, node.image.cropWidth, node.image.cropHeight, iw, ih)
                            else
                                theQuad:setViewport(0, 0, iw, ih, iw, ih)
                            end

                            local qx, qy, qw, qh = theQuad:getViewport()

                            local scale = math.min(node.width / qw, node.height / qh)

                            love.graphics.draw(image, theQuad, node.x, node.y, node.rotation, scale)
                        end
                    end

                    if node.type == 'text' then
                        love.graphics.stacked('all', function()
                            love.graphics.translate(node.x, node.y)
                            love.graphics.rotate(node.rotation)

                            local c = node.text.color
                            love.graphics.setColor(c.r, c.g, c.b, c.a)

                            love.graphics.printf(node.text.text, 0, 0, node.width)
                        end)
                    end
                end

                love.graphics.stacked('all', function() -- Draw selection overlays
                    love.graphics.setColor(0, 1, 0)
                    for id, node in pairs(home.selected) do
                        love.graphics.stacked(function()
                            love.graphics.translate(node.x, node.y)
                            love.graphics.rotate(node.rotation)
                            love.graphics.rectangle('line', 0, 0, node.width, node.height)
                            love.graphics.circle('fill', 0, 0, 4)
                        end)
                    end
                end)
            end

            do -- Players
                for clientId, player in pairs(share.players) do
                    local x, y = player.x, player.y

                    -- Prefer home position
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

local mode = 'none'

local prevMouseWX, prevMouseWY

function client.update(dt)
    local mouseX, mouseY = love.mouse.getPosition()
    local mouseWX, mouseWY = mouseX + cameraX, mouseY + cameraY
    if not (prevMouseWX and prevMouseWY) then
        prevMouseWX, prevMouseWY = mouseWX, mouseWY
    end

    if client.connected then
        do -- Player motion
            local player = share.players[client.id]

            if not (home.x and home.y) then
                home.x, home.y = player.x, player.y
            end

            if home.x and home.y then
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

        do -- Camera panning
            if home.x and home.y then
                if home.x < cameraX + CAMERA_GUTTER then
                    cameraX = home.x - CAMERA_GUTTER
                end
                if home.x + G > cameraX + love.graphics.getWidth() - CAMERA_GUTTER then
                    cameraX = home.x + G - love.graphics.getWidth() + CAMERA_GUTTER
                end
                if home.y < cameraY + CAMERA_GUTTER then
                    cameraY = home.y - CAMERA_GUTTER
                end
                if home.y + G > cameraY + love.graphics.getHeight() - CAMERA_GUTTER then
                    cameraY = home.y + G - love.graphics.getHeight() + CAMERA_GUTTER
                end
            end
        end

        if mode == 'grab' then -- Grab
            local dx, dy = mouseWX - prevMouseWX, mouseWY - prevMouseWY
            for id, node in pairs(home.selected) do
                node.x, node.y = node.x + dx, node.y + dy
            end
        end

        if mode == 'resize' then -- Resize
            for id, node in pairs(home.selected) do
                theTransform:reset()
                theTransform:translate(node.x, node.y)
                theTransform:rotate(node.rotation)
                local prevLX, prevLY = theTransform:inverseTransformPoint(prevMouseWX, prevMouseWY)
                local lx, ly = theTransform:inverseTransformPoint(mouseWX, mouseWY)
                node.width, node.height = math.max(G, node.width * lx / math.max(G, prevLX)), math.max(G, node.height * ly / math.max(G, prevLY))
            end
        end
    end

    prevMouseWX, prevMouseWY = mouseWX, mouseWY
end


--- CHANGING

function client.changing(diff)
    if diff.time and share.time then -- Make sure time only goes forward
        diff.time = math.max(share.time, diff.time)
    end
end


--- MOUSE

function client.mousepressed(x, y, button)
    local wx, wy = x + cameraX, y + cameraY

    if client.connected then
        if mode == 'none' then -- Click to select
            -- Collect hits
            local hits = {}
            for id, node in pairs(share.nodes) do
                theTransform:reset()
                theTransform:translate(node.x, node.y)
                theTransform:rotate(node.rotation)
                local lx, ly = theTransform:inverseTransformPoint(wx, wy)
                if 0 <= lx and lx <= node.width and 0 <= ly and ly <= node.height then
                    table.insert(hits, node)
                end
            end
            table.sort(hits, depthLess)

            -- Pick next in order if something is already selected, else pick first
            local pick
            for i = 1, #hits do
                local j = i == #hits and 1 or i + 1
                if home.selected[hits[i].id] and not home.selected[hits[j].id] then
                    pick = hits[j]
                end
            end
            pick = pick or hits[1]

            -- Select it, or if nothing, just deselect all
            if pick then
                home.selected = { [pick.id] = pick }
            else
                home.selected = {}
            end
        end

        if mode == 'grab' then -- Exit grab
            mode = 'none'
        end

        if mode == 'resize' then -- Exit resize
            mode = 'none'
        end
    end
end


--- KEYBOARD

function client.keypressed(key)
    if key == 'g' then
        if mode == 'grab' then
            mode = 'none'
        else
            mode = 'grab'
        end
    end

    if key == 't' then
        if mode == 'resize' then
            mode = 'none'
        else
            mode = 'resize'
        end
    end
end

function client.keyreleased(key)
end


--- UI

local ui = castle.ui

local function uiRow(id, ...)
    local nArgs = select('#', ...)
    local args = { ... }
    ui.box(id, { flexDirection = 'row' }, function()
        for i = 1, nArgs do
            ui.box(tostring(i), { flex = 1 }, args[i])
            if i < nArgs then
                ui.box('space', { width = 20 }, function() end)
            end
        end
    end)
end

local defaults = {
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
        color = { r = 0, g = 0, b = 0, a = 1 },
    }
}

function client.uiupdate()
    if client.connected then
        ui.tabs('main', function()
            ui.tab('nodes', function()
                if ui.button('new node') then
                    local id = uuid()
                    local typ = 'image'
                    home.selected = {
                        [id] = {
                            id = id,
                            type = typ,
                            x = cameraX + 0.5 * love.graphics.getWidth(),
                            y = cameraY + 0.5 * love.graphics.getHeight(),
                            rotation = 0,
                            depth = 1,
                            width = 4 * G,
                            height = 4 * G,
                            [typ] = defaults[typ],
                        },
                    }
                end

                for id, node in pairs(home.selected) do
                    ui.section('selected node', { defaultOpen = true }, function()
                        ui.dropdown('type', node.type, { 'image', 'text' }, {
                            onChange = function(newType)
                                node[node.type] = nil
                                node.type = newType
                                node[node.type] = defaults[node.type]
                            end,
                        })

                        uiRow('position', function()
                            node.x = ui.numberInput('x', node.x)
                        end, function()
                            node.y = ui.numberInput('y', node.y)
                        end)

                        uiRow('rotation-depth', function()
                            ui.numberInput('rotation', node.rotation * 180 / math.pi, {
                                onChange = function (newVal)
                                    node.rotation = newVal * math.pi / 180
                                end
                            })
                        end, function()
                            node.depth = ui.numberInput('depth', node.depth)
                        end)

                        uiRow('size', function()
                            node.width = ui.numberInput('width', node.width)
                        end, function()
                            node.height = ui.numberInput('height', node.height)
                        end)

                        if node.type == 'image' then
                            node.image.url = ui.textInput('image url', node.image.url)

                            node.image.smoothScaling = ui.toggle('smooth scaling off', 'smooth scaling on', node.image.smoothScaling)

                            node.image.crop = ui.toggle('crop off', 'crop on', node.image.crop)

                            if node.image.crop then
                                uiRow('crop-xy', function()
                                    node.image.cropX = ui.numberInput('crop x', node.image.cropX)
                                end, function()
                                    node.image.cropY = ui.numberInput('crop y', node.image.cropY)
                                end)
                                uiRow('crop-size', function()
                                    node.image.cropWidth = ui.numberInput('crop width', node.image.cropWidth)
                                end, function()
                                    node.image.cropHeight = ui.numberInput('crop height', node.image.cropHeight)
                                end)

                                if ui.button('reset crop') then
                                    local image = imageFromUrl(node.image.url)
                                    if image then
                                        node.image.cropX, node.image.cropY = 0, 0
                                        node.image.cropWidth, node.image.cropHeight = image:getWidth(), image:getHeight()
                                    end
                                end
                            end
                        end

                        if node.type == 'text' then
                            node.text.text = ui.textArea('text', node.text.text)

                            local c = node.text.color
                            c.r, c.g, c.b, c.a = ui.colorPicker('color', c.r, c.g, c.b, c.a)
                        end
                    end)
                end
            end)

            ui.tab('world', function()
                local bgc = share.backgroundColor
                ui.colorPicker('background color', bgc.r, bgc.g, bgc.b, 1, {
                    onChange = function(c)
                        client.send('setBackgroundColor', c)
                    end,
                })
            end)

            ui.tab('help', function()
                ui.markdown([[
in edit world you can walk around, explore nodes placed by other people, or place your own nodes!

use the W, A, S and D keys to walk around.

nodes can be images, and soon text and other types of nodes will be supported. 

to place a node, in the 'nodes' tab, hit 'new node' and you will see an image appear in the center of your screen. you can change the url of the image, change its size or other properties in the sidebar.

to select an existing node, just click it.

press G to enter grab mode -- the node will move with your mouse cursor. press G again or click to exit grab mode. press T to enter resize mode, where the node's width and height will change as you move your mouse cursor. press T again or click to exit resize mode.
                ]])
            end)
        end)
    end
end