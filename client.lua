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

local function cloneValue(t)
    local typ = type(t)
    if typ == 'nil' or typ == 'boolean' or typ == 'number' or typ == 'string' then
        return t
    elseif typ == 'table' or typ == 'userdata' then
        local u = {}
        for k, v in pairs(t) do
            u[cloneValue(k)] = cloneValue(v)
        end
        return u
    else
        error('clone: bad type')
    end
end

local function newNode()
    local id = uuid()

    home.selected = {}
    home.selected[id] = NODE_COMMON_DEFAULTS
    local newNode = home.selected[id]

    newNode.id = id
    newNode[newNode.type] = NODE_TYPE_DEFAULTS[newNode.type]
    newNode.x, newNode.y = cameraX + 0.5 * love.graphics.getWidth(), cameraY + 0.5 * love.graphics.getHeight()
end

local function deleteNode(node)
    home.deleted[node.id] = true
    home.selected[node.id] = nil
end

local function cloneNode(node)
    local newId = uuid()
    local newNode = cloneValue(node)
    newNode.id = newId
    newNode.name = ''
    newNode.x, newNode.y = newNode.x + G, newNode.y + G
    home.selected = { [newId] = newNode }
end


--- LOAD

local cameraX, cameraY

local theQuad, theTransform

local secondaryId

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

    do -- Deleted
        home.deleted = {}
    end

    do -- Post opened
        local post = castle.post.getInitialPost()
        if post then
            client.send('postOpened', post)
        end
    end
end


--- DRAW

local imageFromUrl
do
    local cache = {} -- url -> { image = image }
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

local fontFromUrl
do
    local cache = {} -- url --> size --> { font = font }
    function fontFromUrl(url, size)
        local cacheFontUrl = cache[url]
        if not cacheFontUrl then
            cacheFontUrl = {}
            cache[url] = cacheFontUrl
        end
        local cached = cacheFontUrl[size]
        if not cached then
            cached = {}
            cacheFontUrl[size] = cached
            if url == '' then
                cached.font = love.graphics.newFont(size)
            else
                network.async(function()
                    cached.font = love.graphics.newFont(url, size)
                end)
            end
        end
        return cached.font
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

                local portals, groups, secondary = {}, {}, nil

                for _, node in ipairs(order) do -- Draw order
                    if node.portalEnabled then
                        table.insert(portals, node)
                    end

                    if secondaryId == node.id then
                        secondary = node
                    end

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

                            local font = fontFromUrl(node.text.fontUrl, node.text.fontSize)
                            if font then
                                love.graphics.setFont(font)
                                love.graphics.printf(node.text.text, 0, 0, node.width)
                            end
                        end)
                    end

                    if node.type == 'group' then
                        table.insert(groups, node)
                    end
                end

                love.graphics.stacked('all', function() -- Draw group overlays
                    love.graphics.setColor(1, 1, 0)
                    for _, node in ipairs(groups) do
                        love.graphics.stacked(function()
                            love.graphics.translate(node.x, node.y)
                            love.graphics.rotate(node.rotation)
                            love.graphics.rectangle('line', 0, 0, node.width, node.height)
                        end)
                    end
                end)

                love.graphics.stacked('all', function() -- Draw portal overlays
                    love.graphics.setColor(1, 0, 1)
                    for _, node in ipairs(portals) do
                        love.graphics.stacked(function()
                            love.graphics.translate(node.x, node.y)
                            love.graphics.rotate(node.rotation)
                            love.graphics.rectangle('line', 0, 0, node.width, node.height)
                        end)
                    end
                end)

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

                if secondary then
                    love.graphics.stacked('all', function() -- Draw secondary overlay
                        love.graphics.setColor(1, 0, 0)
                        love.graphics.translate(secondary.x, secondary.y)
                        love.graphics.rotate(secondary.rotation)
                        love.graphics.rectangle('line', -0.1 * G, -0.1 * G, secondary.width + 0.2 * G, secondary.height + 0.2 * G)
                    end)
                end
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

            do -- Initialize
                if not (home.x and home.y) then
                    home.x, home.y = player.x, player.y
                end
            end

            do -- Walk
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

            do -- Portals
                local wx, wy = home.x + 0.5 * G, home.y + 0.5 * G

                for id, node in pairs(share.nodes) do
                    if node.portalEnabled then
                        local targetId = share.names[node.portalTargetName]
                        local target = targetId and share.nodes[targetId]
                        if target then
                            theTransform:reset()
                            theTransform:translate(node.x, node.y)
                            theTransform:rotate(node.rotation)
                            local lx, ly = theTransform:inverseTransformPoint(wx, wy)
                            if 0 <= lx and lx <= node.width and 0 <= ly and ly <= node.height then
                                theTransform:reset()
                                theTransform:translate(target.x, target.y)
                                theTransform:rotate(target.rotation)
                                local tx, ty = theTransform:transformPoint(0.5 * target.width, 0.5 * target.height)
                                home.x, home.y = tx - 0.5 * G, ty - 0.5 * G
                                cameraX, cameraY = tx - 0.5 * love.graphics.getWidth(), ty - 0.5 * love.graphics.getHeight()
                            end
                        end
                    end
                end
            end
        end

        do -- Camera panning
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

        do -- Clear deleteds
            for id in pairs(home.deleted) do
                if not share.nodes[id] then
                    home.deleted[id] = nil
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

        if mode == 'rotate' then -- Rotate
            for id, node in pairs(home.selected) do
                theTransform:reset()
                theTransform:translate(node.x, node.y)
                theTransform:rotate(node.rotation)
                local prevLX, prevLY = theTransform:inverseTransformPoint(prevMouseWX, prevMouseWY)
                local lx, ly = theTransform:inverseTransformPoint(mouseWX, mouseWY)
                node.rotation = node.rotation + math.atan2(ly, lx) - math.atan2(prevLY, prevLX)
                while node.rotation > math.pi do
                    node.rotation = node.rotation - 2 * math.pi
                end
                while node.rotation < -math.pi do
                    node.rotation = node.rotation + 2 * math.pi
                end
            end
        end
    end

    prevMouseWX, prevMouseWY = mouseWX, mouseWY
end


--- MOUSE

function client.mousepressed(x, y, button)
    local wx, wy = x + cameraX, y + cameraY

    if client.connected then
        if mode == 'none' then -- Click to select
            local isSelected, select -- Decide between primary or secondary selection
            if button == 1 then -- Primary
                function isSelected(id)
                    return home.selected[id]
                end
                function select(node)
                    if node then
                        home.selected = { [node.id] = node }
                    else
                        home.selected = {}
                    end
                end
            elseif button == 2 then -- Secondary
                function isSelected(id)
                    return secondaryId == id
                end
                function select(node)
                    if node then
                        secondaryId = node.id
                    else
                        secondaryId = nil
                    end
                end
            end

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
                if isSelected(hits[i].id) and not isSelected(hits[j].id) then
                    pick = hits[j]
                end
            end
            pick = pick or hits[1]

            -- Select it, or if nothing, just deselect all
            select(pick)
        end

        if mode == 'grab' then -- Exit grab
            mode = 'none'
        end

        if mode == 'resize' then -- Exit resize
            mode = 'none'
        end

        if mode == 'rotate' then -- Exit rotate
            mode = 'none'
        end
    end
end


--- KEYBOARD

function client.keypressed(key)
    if key == 'g' then -- Grab
        if mode == 'grab' then
            mode = 'none'
        else
            mode = 'grab'
        end
    end

    if key == 't' then -- Resize
        if mode == 'resize' then
            mode = 'none'
        else
            mode = 'resize'
        end
    end

    if key == 'r' then -- Rotate
        if mode == 'rotate' then
            mode = 'none'
        else
            mode = 'rotate'
        end
    end

    if love.keyboard.isDown('lshift') or love.keyboard.isDown('rshift') then
        if key == 'p' then -- Set parent
            if secondaryId then
                local secondary = share.nodes[secondaryId]
                if secondary then
                    if secondary.type == 'group' then
                        for id, node in pairs(home.selected) do
                            addToGroup(node, secondary)
                        end
                    else
                        print('only groups can be parents!')
                    end
                end
            end
        end

        if key == 'n' then -- New
            newNode()
        end

        if key == 'backspace' or key == 'delete' then -- Delete
            for id, node in pairs(home.selected) do
                deleteNode(node)
            end
        end

        if key == 'c' then -- Clone
            for id, node in pairs(home.selected) do
                cloneNode(node)
            end
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

function client.uiupdate()
    if client.connected then
        ui.tabs('main', function()
            ui.tab('help', function()
                ui.markdown([[
in edit world you can walk around the world, explore nodes placed by other people, or place your own nodes! **invite** friends through the 'Invite: ' link in the Castle bottom bar to collaborate.

### walking

use the W, A, S and D keys to walk around.

### creating nodes

to create a node, in the **'nodes' tab**, hit **'new'** and you will see an image appear in the center of your screen. this is a new node!

use the **'type' dropdown** to switch to a different type of node (such as text).

### editing nodes

to **select** an existing node, just **click** it. when you make a new node, it is already selected. you can change its **properties** in the 'nodes' tab in the sidebar.

- **images**: you can change the source **url** of the image, **crop** the image or change whether it scales **smooth**ly.
- **text**: you can change the **text** that is displayed, set its **font size** and **color**, or select a **source url** for the font used.

### moving nodes

with a node selected, press **G** to enter **grab mode** -- the node will move with your mouse cursor. press G again or click to exit grab mode.

similarly, **T** enters **resize mode** where you can use the mouse to change the node's width and height, and **R** enters **rotate mode** where you can change the node's rotation.

### naming nodes

nodes can optionally have **names** so that they can be referenced from other nodes. a name is considered invalid if some other node is already using it.

names are useful when making **portals** (see below).

### portals

any node can be turned into a **portal** by turning 'portal' on in its properties. you can then enter the name of a target node in 'portal target name'. then, when a player touches the portal, they will be **teleported** to the target!

portals always show a magenta rectangle around them.

### editing world properties

in the **'world' tab** you can edit **world-level** properties such as the **background color**.

### saving the world

in the 'world' tab, hit **'post world!'** to create a post storing the world. then you (or anyone!) can **open that post** to start a **new session** with the saved world.
                ]])
            end)

            ui.tab('nodes', function()
                if ui.button('new') then
                    newNode()
                end

                ui.markdown('---')

                for id, node in pairs(home.selected) do
                    uiRow('delete-clone', function()
                        if ui.button('delete', { kind = 'danger' }) then
                            deleteNode(node)
                        end
                    end, function()
                        if ui.button('clone') then
                            cloneNode(node)
                        end
                    end)

                    ui.markdown('---')

                    ui.dropdown('type', node.type, { 'image', 'text', 'group' }, {
                        onChange = function(newType)
                            node[node.type] = nil
                            node.type = newType
                            node[node.type] = NODE_TYPE_DEFAULTS[node.type]
                        end,
                    })

                    local nameInvalid = false
                    if node.name ~= '' then
                        local usedId = share.names[node.name]
                        if usedId and usedId ~= node.id then
                            nameInvalid = true
                        end
                    end
                    node.name = ui.textInput('name', node.name, {
                        invalid = nameInvalid,
                        invalidText = 'this name is in use by a different node',
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

                    node.portalEnabled = ui.toggle('portal', 'portal', node.portalEnabled)
                    if node.portalEnabled then
                        node.portalTargetName = ui.textInput('portal target name', node.portalTargetName, {
                            invalid = share.names[node.portalTargetName] == nil,
                            invalidText = node.portalTargetName == '' and 'portals need the name of a target node' or 'there is no node with this name'
                        })
                    end

                    ui.markdown('---')

                    if node.type == 'image' then
                        node.image.url = ui.textInput('image url', node.image.url)

                        uiRow('smooth-scaling-crop', function()
                            node.image.smoothScaling = ui.toggle('smooth scaling', 'smooth scaling', node.image.smoothScaling)
                        end, function()
                            node.image.crop = ui.toggle('crop', 'crop', node.image.crop)
                        end)

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

                        node.text.fontUrl = ui.textInput('font url', node.text.fontUrl)

                        node.text.fontSize = ui.slider('font size', node.text.fontSize, MIN_FONT_SIZE, MAX_FONT_SIZE)
                        node.text.fontSize = math.max(MIN_FONT_SIZE, math.min(node.text.fontSize, MAX_FONT_SIZE))

                        local c = node.text.color
                        c.r, c.g, c.b, c.a = ui.colorPicker('color', c.r, c.g, c.b, c.a)
                    end

                    if node.type == 'group' then
                        for childId in pairs(node.group.childrenIds) do
                            local child = share.nodes[childId]
                            if child then
                                uiRow('child-' .. childId, function()
                                    ui.markdown(child.type)
                                end, function()
                                    uiRow('select-unlink', function()
                                        if ui.button('select') then
                                            home.selected = { [child.id] = child }
                                        end
                                    end, function()
                                        if ui.button('unlink') then
                                            removeFromGroup(node, child)
                                        end
                                    end)
                                end)
                            end
                        end
                    end
                end
            end)

            ui.tab('world', function()
                local bgc = share.backgroundColor
                ui.colorPicker('background color', bgc.r, bgc.g, bgc.b, 1, {
                    onChange = function(c)
                        client.send('setBackgroundColor', c)
                    end,
                })

                if ui.button('post world!') then
                    network.async(function()
                        castle.post.create {
                            message = 'A world we created!',
                            media = 'capture',
                            data = {
                                backgroundColor = share.backgroundColor,
                                nodes = cloneValue(share.nodes),
                            },
                        }
                    end)
                end
            end)
        end)
    end
end