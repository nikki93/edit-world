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


--- LOCALS

local parentChildIndex = {}     -- `parent.id` -> `child.id` -> `true`, for all `child.parentId == parent.id`
local parentTagChildIndex = {}  -- `parent.id` -> `tag` -> `child.id` -> `true`, for all `child.tags[tag] and child.parentId == parent.id`

local mode = 'none'

local selections = {} -- node id -> `true` for selections we control
local conflictingSelections = {} -- node id -> `true` for attempted selections someone else controls
local secondarySelection = nil -- node id

local cameraX, cameraY = 0, 0
local cameraW, cameraH = 800, 450


--- UTIL

local function getNodeWithId(id)
    return id and ((home.controlled and home.controlled[id]) or (share.nodes and share.nodes[id]))
end

local getParentWorldSpace, getWorldSpace, clearWorldSpace
do
    local cache = {}

    local rootSpace = {
        transform = love.math.newTransform(),
        depth = 0,
    }

    function getParentWorldSpace(node)
        return getWorldSpace(getNodeWithId(node.parentId))
    end

    function getWorldSpace(node)
        if node == nil then
            return rootSpace
        else
            local cached = cache[node]
            if not cached then
                cached = {}
                cache[node] = cached

                local parentWorldSpace = getParentWorldSpace(node)
                if not parentWorldSpace.transform then
                    parentWorldSpace = rootSpace
                end
                cached.transform = parentWorldSpace.transform:clone():translate(node.x, node.y):rotate(node.rotation)
                cached.depth = parentWorldSpace.depth + node.depth
            end
            return cached
        end
    end

    function clearWorldSpace()
        cache = {}
    end
end

local function getTransformRotation(transform)
    local ox, oy = transform:transformPoint(0, 0)
    local ux, uy = transform:transformPoint(1, 0)
    return math.atan2(uy - oy, ux - ox)
end

local function depthLess(node1, node2)
    local space1, space2 = getWorldSpace(node1), getWorldSpace(node2)
    if space1.depth < space2.depth then
        return true
    end
    if space1.depth > space2.depth then
        return false
    end
    return node1.id < node2.id
end

local function hasChildren(idOrNode)
    local node = type(idOrNode) ~= 'string' and idOrNode or getNodeWithId(idOrNode)
    if node.type == 'group'then
        for childId in pairs(node.group.childrenIds) do
            return true
        end
    end
    return false
end

local function updateIndices(oldParentId, newParentId, newNode)
    local nodeId = newNode.id
    if oldParentId then
        if oldParentId ~= newParentId then -- Parent changed, remove from `parentChildIndex` for old parent
            local childIndex = parentChildIndex[oldParentId]
            if childIndex then
                childIndex[nodeId] = nil
                if not next(childIndex) then -- Empty?
                    parentChildIndex[oldParentId] = nil
                end
            end
        end

        local tagChildIndex = parentTagChildIndex[oldParentId]
        if tagChildIndex then -- Remove from `parentTagChildIndex` for old parent
            for tag, childIndex in pairs(tagChildIndex) do -- Need to go through every tag in the index
                childIndex[nodeId] = nil
                if not next(childIndex) then
                    tagChildIndex[tag] = nil
                end
            end
            if not next(tagChildIndex) then
                parentTagChildIndex[oldParentId] = nil
            end
        end
    end
    if newParentId then
        if oldParentId ~= newParentId then -- Parent changed, add to `parentChildIndex` for new parent
            local childIndex = parentChildIndex[newParentId]
            if not childIndex then
                childIndex = {}
                parentChildIndex[newParentId] = childIndex
            end
            childIndex[nodeId] = true
        end

        local tagChildIndex 
        for tag in pairs(newNode.tags) do -- Add to `parentChildIndex` for new parent
            local tagChildIndex = tagChildIndex or parentTagChildIndex[newParentId]
            if not tagChildIndex then
                tagChildIndex = {}
                parentTagChildIndex[newParentId] = tagChildIndex
            end
            local childIndex = tagChildIndex[tag]
            if not childIndex then
                childIndex = {}
                tagChildIndex[tag] = childIndex
            end
            childIndex[nodeId] = true
        end
    end
    newNode.parentId = newParentId
end

local function deselectAll()
    selections = {}
    conflictingSelections = {}
    secondarySelection = nil
    home.controlled = {}
end

local function selectOnly(node)
    selections = { [node.id] = true }
    home.controlled[node.id] = node
end

local function newNode()
    -- Deselect all
    deselectAll()

    -- Create
    local newId = uuid()
    local newNode = NODE_COMMON_DEFAULTS
    newNode.id = newId
    newNode.rngState = love.math.newRandomGenerator(love.math.random()):getState()
    newNode[newNode.type] = NODE_TYPE_DEFAULTS[newNode.type]
    newNode.x, newNode.y = cameraX, cameraY

    -- Select
    selectOnly(newNode)
end

local function deleteSelectedNodes()
    for id in pairs(selections) do
        if hasChildren(id) then -- Shallow delete only for now
            print("can't delete a group that has children -- you must either detach or delete the children first!")
            return
        end
        local node = getNodeWithId(id)
        if node then
            updateIndices(node.parentId, nil, node)
        end
        home.deleted[id] = true
        selections[id] = nil
        home.controlled[id] = nil
    end
end

local function cloneSelectedNodes()
    for id in pairs(selections) do
        local node = getNodeWithId(id)

        -- Deselect all
        deselectAll()

        -- Clone
        local newId = uuid()
        local newNode = cloneValue(node)
        newNode.id = newId
        newNode.rngState = love.math.newRandomGenerator(love.math.random()):getState()
        newNode.x, newNode.y = newNode.x + G, newNode.y + G
        if newNode.type == 'group' then -- Shallow clone only for now
            newNode.group.childrenIds = {}
            newNode.group.tagIndices = {}
        end
        if newNode.parentId then
            updateIndices(nil, newNode.parentId, newNode)
        end

        -- Select
        selectOnly(newNode)
    end
end


--- LOAD

local theQuad

local defaultFont

local defaultImage

function client.load()
    theQuad = love.graphics.newQuad(0, 0, 32, 32, 32, 32)

    defaultFont = love.graphics.newFont(14)
    
    defaultImage = love.graphics.newImage('checkerboard.png')
end


--- CONNECT

function client.connect()
    do -- Me
        home.me = castle.user.getMe()
    end

    do -- Controlled
        home.controlled = {}
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
        return cached.image or defaultImage
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

local function drawBox(node)
    love.graphics.stacked(function()
        love.graphics.applyTransform(getWorldSpace(node).transform)
        love.graphics.rectangle('line', -0.5 * node.width, -0.5 * node.height, node.width, node.height)
    end)
end

function client.draw()
    if client.connected then
        do -- Background color
            local bgc = share.settings.backgroundColor
            love.graphics.clear(bgc.r, bgc.g, bgc.b)
        end

        love.graphics.stacked('all', function() -- Camera transform
            love.graphics.scale(love.graphics.getWidth() / cameraW, love.graphics.getHeight() / cameraH)
            love.graphics.translate(-cameraX + 0.5 * cameraW, -cameraY + 0.5 * cameraH)

            do -- Nodes
                local order = {}
                do -- Collect draw order, preferring controlled versions
                    for id, node in pairs(share.nodes) do -- Share, skipping controlled
                        if not home.controlled[id] then
                            table.insert(order, node)
                        end
                    end
                    for id, node in pairs(home.controlled) do -- Controlled
                        table.insert(order, node)
                    end
                    table.sort(order, depthLess)
                end

                local groups, sounds = {}, {}

                for _, node in ipairs(order) do -- Draw in order
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
                            local transform = getWorldSpace(node).transform:clone():translate(-0.5 * node.width, -0.5 * node.height):scale(scale)
                            local c = node.image.color
                            love.graphics.setColor(c.r, c.g, c.b, c.a)
                            love.graphics.draw(image, theQuad, transform)
                        end
                    end

                    if node.type == 'text' then
                        local font = fontFromUrl(node.text.fontUrl, node.text.fontSize)
                        if font then
                            love.graphics.setFont(font)
                            local c = node.text.color
                            local transform = getWorldSpace(node).transform:clone():translate(-0.5 * node.width, -0.5 * node.height)
                            love.graphics.printf({ { c.r, c.g, c.b, c.a }, node.text.text }, transform, node.width)
                        end
                    end

                    if node.type == 'group' then
                        table.insert(groups, node)
                    end
                    if node.type == 'sound' then
                        table.insert(sounds, node)
                    end
                end

                love.graphics.stacked('all', function() -- Draw sound overlays
                    love.graphics.setColor(1, 0, 1)
                    for _, node in ipairs(sounds) do
                        drawBox(node)
                    end
                end)

                love.graphics.stacked('all', function() -- Draw group overlays
                    love.graphics.setColor(0.8, 0.5, 0.1)
                    for _, node in ipairs(groups) do
                        drawBox(node)
                    end
                end)

                love.graphics.stacked('all', function() -- Draw conflicting selection overlays
                    love.graphics.setColor(0.5, 0, 1)
                    for id in pairs(conflictingSelections) do
                        local node = getNodeWithId(id)
                        if node then
                            drawBox(node)
                        end
                    end
                end)

                love.graphics.stacked('all', function() -- Draw selection overlays
                    love.graphics.setColor(0, 1, 0)
                    for id, node in pairs(selections) do
                        local node = getNodeWithId(id)
                        if node then
                            drawBox(node)
                        end
                    end
                end)

                if secondarySelection then -- Draw secondary slection overlay
                    local secondaryNode = getNodeWithId(secondarySelection)
                    if secondaryNode then
                        love.graphics.stacked('all', function()
                            love.graphics.setColor(1, 0, 0)
                            drawBox(secondaryNode)
                        end)
                    end
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
                            love.graphics.setColor(1, 1, 1, 1)
                            love.graphics.draw(photo, x - 0.5 * G, y - 0.5 * G, 0, G / photo:getWidth(), G / photo:getHeight())
                        end
                    end
                end
            end
        end)

        love.graphics.stacked('all', function() -- Bottom bar
            local lightViolet = { 0.882, 0.824, 0.965 }
            local darkViolet = { 0.722, 0.58, 0.914 }
            local white = { 1, 1, 1 }

            local background = lightViolet
            local separator = darkViolet
            local textColor = white

            local screenW, screenH = love.graphics.getDimensions()
            local fontH = defaultFont:getHeight()
            local pad = 4
            local separatorW = 4

            local barH = fontH + 2 * pad

            love.graphics.translate(0, screenH - barH)
            love.graphics.setColor(background)
            love.graphics.rectangle('fill', 0, 0, screenW, barH)

            local left, right = 0, screenW

            local function leftText(text)
                local textW = defaultFont:getWidth(text)
                local blockW = textW + 2 * pad
                love.graphics.setColor(separator)
                love.graphics.rectangle('fill', left, 0, blockW, barH)
                love.graphics.setColor(textColor)
                love.graphics.print(text, left + pad, pad)
                left = left + blockW + separatorW
            end

            local function rightText(text)
                local textW = defaultFont:getWidth(text)
                local blockW = textW + 2 * pad
                love.graphics.setColor(separator)
                love.graphics.rectangle('fill', right - blockW, 0, blockW, barH)
                love.graphics.setColor(textColor)
                love.graphics.print(text, right - blockW + pad, pad)
                right = right - blockW - separatorW
            end

            if mode ~= 'none' then
                leftText(mode)
            end

            do
                local selectCount = 0
                for id, node in pairs(selections) do
                    selectCount = selectCount + 1
                end
                if selectCount >= 1 then
                    leftText('select ' .. selectCount)
                end
            end

            if secondarySelection then
                leftText('secondary 1')
            end

            rightText('fps ' .. love.timer.getFPS())
        end)
    else -- Not connected
        love.graphics.print('connecting...', 20, 20)
    end
end


--- UPDATE

local prevMouseWX, prevMouseWY
local prevMouseDown = { false, false }

function client.update(dt)
    local mouseX, mouseY = love.mouse.getPosition()
    local gW, gH = love.graphics.getWidth(), love.graphics.getHeight()
    local mouseWX, mouseWY = (mouseX - 0.5 * gW) * (cameraW / gW) + cameraX, (mouseY - 0.5 * gH) * (cameraH / gH) + cameraY
    if not (prevMouseWX and prevMouseWY) then
        prevMouseWX, prevMouseWY = mouseWX, mouseWY
    end
    for button = 1, 2 do
        if love.mouse.isDown(button) and not prevMouseDown[button] then
            client.mousepressed(mouseX, mouseY, button)
        end
        prevMouseDown[button] = love.mouse.isDown(button)
    end

    if client.connected then
        clearWorldSpace()

        do -- Defaults
            NODE_TYPE_DEFAULTS.image.smoothScaling = share.settings.defaultSmoothScaling
        end

        do -- Deletions
            if secondarySelection and not share.nodes[secondarySelection] then
                secondarySelection = nil
            end
            for id in pairs(conflictingSelections) do
                if not share.nodes[id] then
                    conflictingSelections[id] = nil
                end
            end
            for id in pairs(home.deleted) do
                if not share.nodes[id] then
                    home.deleted[id] = nil
                end
            end
        end

        -- do -- Acquirable conflicting selections
        --     for id in pairs(conflictingSelections) do
        --         if not share.locks[id] or share.locks[id] == client.id then
        --             conflictingSelections[id] = nil
        --             home.selected = { [id] = share.nodes[id] }
        --         end
        --     end
        -- end

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
        end

        do -- Camera panning
            local gutter = CAMERA_GUTTER * (cameraW / love.graphics.getWidth())
            if home.x - 0.5 * G < cameraX - 0.5 * cameraW + gutter then
                cameraX = home.x - 0.5 * G + 0.5 * cameraW - gutter
            end
            if home.x + 0.5 * G > cameraX + 0.5 * cameraW - gutter then
                cameraX = home.x + 0.5 * G - 0.5 * cameraW + gutter
            end
            if home.y - 0.5 * G < cameraY - 0.5 * cameraH + gutter then
                cameraY = home.y - 0.5 * G + 0.5 * cameraH - gutter
            end
            if home.y + 0.5 * G > cameraY + 0.5 * cameraH - gutter then
                cameraY = home.y + 0.5 * G - 0.5 * cameraH + gutter
            end
        end

        do -- Run think rules
            for id, node in pairs(share.nodes) do
                if not home.controlled[id] then
                    runThinkRules(node, getNodeWithId, { parentChildIndex = parentChildIndex, parentTagChildIndex = parentTagChildIndex })
                end
            end
            for id, node in pairs(home.controlled) do
                runThinkRules(node, getNodeWithId, { parentChildIndex = parentChildIndex, parentTagChildIndex = parentTagChildIndex })
            end
        end

        if mode == 'grab' then -- Grab
            for id in pairs(selections) do
                local node = home.controlled[id]
                if node then
                    local transform = getParentWorldSpace(node).transform
                    local prevLX, prevLY = transform:inverseTransformPoint(prevMouseWX, prevMouseWY)
                    local lx, ly = transform:inverseTransformPoint(mouseWX, mouseWY)
                    node.x, node.y = node.x + lx - prevLX, node.y + ly - prevLY
                end
            end
        end

        if mode == 'resize' then -- Resize
            for id in pairs(selections) do
                local node = home.controlled[id]
                if node then
                    local transform = getWorldSpace(node).transform
                    local prevLX, prevLY = transform:inverseTransformPoint(prevMouseWX, prevMouseWY)
                    local lx, ly = transform:inverseTransformPoint(mouseWX, mouseWY)
                    if math.abs(prevLX) >= 0.5 * G and math.abs(ly) >= 0.5 * G then
                        node.width = math.max(G, node.width * lx / prevLX)
                    end
                    if math.abs(prevLY) >= 0.5 * G and math.abs(ly) >= 0.5 * G then
                        node.height = math.max(G, node.height * ly / prevLY)
                    end
                end
            end
        end

        if mode == 'rotate' then -- Rotate
            for id in pairs(selections) do
                local node = home.controlled[id]
                if node then
                    local transform = getWorldSpace(node).transform
                    local prevLX, prevLY = transform:inverseTransformPoint(prevMouseWX, prevMouseWY)
                    local lx, ly = transform:inverseTransformPoint(mouseWX, mouseWY)
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
    end

    prevMouseWX, prevMouseWY = mouseWX, mouseWY
end


--- MOUSE

function client.mousepressed(x, y, button)
    prevMouseDown[button] = true

    local gW, gH = love.graphics.getWidth(), love.graphics.getHeight()
    local wx, wy = (x - 0.5 * gW) * (cameraW / gW) + cameraX, (y - 0.5 * gH) * (cameraH / gH) + cameraY

    if client.connected then
        if mode == 'none' then -- Click to select
            local isSelected, select -- Decide between primary or secondary selection
            if button == 1 then -- Primary
                function isSelected(id)
                    return conflictingSelections[id] or selections[id]
                end
                function select(node)
                    deselectAll()
                    if share.locks[node.id] and share.locks[node.id] ~= client.id then
                        conflictingSelections = { [node.id] = true }
                    else
                        selections = { [node.id] = true }
                        home.controlled[node.id] = node
                    end
                end
            elseif button == 2 then -- Secondary
                function isSelected(id)
                    return secondarySelection == id
                end
                function select(node)
                    secondarySelection = node.id
                end
            end

            -- Collect hits
            local hits = {}
            for id, node in pairs(share.nodes) do
                local lx, ly = getWorldSpace(node).transform:inverseTransformPoint(wx, wy)
                if math.abs(lx) <= 0.5 * node.width and math.abs(ly) <= 0.5 * node.height then
                    table.insert(hits, node)
                end
            end
            table.sort(hits, depthLess)

            -- Pick next in order if something is already selected, else pick first
            local pick
            for i = #hits, 1, -1 do
                local j = i == 1 and #hits or i - 1
                if isSelected(hits[i].id) and not isSelected(hits[j].id) then
                    pick = hits[j]
                end
            end
            pick = pick or hits[#hits]

            -- Select it, or if nothing, just deselect all
            if pick then
                select(pick)
            else
                deselectAll()
            end
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

function client.wheelmoved(x, y)
    local cameraSizes = {
        { },
        { 640, 360 },
        { 800, 450 }, -- Default
        { 1200, 675 },
        { 1600, 900 },
        { 2400, 1350 },
        { },
    }
    if y > 0 then -- Zoom in
        for i = 1, #cameraSizes do
            if cameraSizes[i][1] == cameraW and cameraSizes[i - 1][1] then
                cameraW, cameraH = cameraSizes[i - 1][1], cameraSizes[i - 1][2]
                break
            end
        end
    end
    if y < 0 then -- Zoom out
        for i = 1, #cameraSizes do
            if cameraSizes[i][1] == cameraW and cameraSizes[i + 1][1] then
                cameraW, cameraH = cameraSizes[i + 1][1], cameraSizes[i + 1][2]
                break
            end
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

    if key == 'p' then -- Parent
        local secondaryNode = secondarySelection and getNodeWithId(secondarySelection)
        if secondaryNode then -- New parent
            if secondaryNode.type == 'group' then
                for id in pairs(selections) do
                    local node = home.controlled[id]
                    if node then
                        -- Make sure no cycles
                        local cycle = false
                        do
                            local curr = secondaryNode
                            while curr do
                                if curr.id == node.id then
                                    cycle = true
                                end
                                curr = getNodeWithId(curr.parentId)
                            end
                        end
                        if not cycle then
                            -- Update local transform
                            local secondaryTransform = getWorldSpace(secondaryNode).transform
                            local nodeTransform = getWorldSpace(node).transform
                            node.x, node.y = secondaryTransform:inverseTransformPoint(nodeTransform:transformPoint(0, 0))
                            node.rotation = getTransformRotation(nodeTransform) - getTransformRotation(secondaryTransform)

                            -- Unlink old, link new
                            updateIndices(node.parentId, secondarySelection, node)
                        else
                            print("can't add a node as a child of itself or one of its descendants!")
                        end
                    end
                end
            else
                print('only groups can be parents!')
            end
        else -- Remove parent
            for id in pairs(selections) do
                local node = home.controlled[id]
                if node then
                    local prevParent = getNodeWithId(node.parentId)
                    local nodeTransform = getWorldSpace(node).transform
                    node.x, node.y = nodeTransform:transformPoint(0, 0)
                    node.rotation = getTransformRotation(nodeTransform)
                    updateIndices(node.parentId, nil, node)
                end
            end
        end
    end

    if key == 'n' then -- New
        newNode()
    end

    if key == 'backspace' or key == 'delete' then -- Delete
        deleteSelectedNodes()
    end

    if key == 'c' then -- Clone
        cloneSelectedNodes()
    end
end

function client.keyreleased(key)
end


--- UI

local ui = castle.ui

local function uiRow(id, ...)
    local nArgs = select('#', ...)
    local args = { ... }
    ui.box(id, { flexDirection = 'row', alignItems = 'center' }, function()
        for i = 1, nArgs do
            ui.box(tostring(i), { flex = 1 }, args[i])
            if i < nArgs then
                ui.box('space', { width = 20 }, function() end)
            end
        end
    end)
end

local function uiSpacer()
    ui.box('spacer', { height = 40 }, function() end)
end

local nodeSectionOpen = true
local typeSectionOpen = true
local ruleSectionOpen = {}

function client.uiupdate()
    if client.connected then
        ui.tabs('main', function()
            ui.tab('nodes', function()
                uiRow('top-bar', function()
                    if ui.button('new') then
                        newNode()
                    end
                end, function()
                    if next(selections) and ui.button('delete', { kind = 'danger' }) then
                        deleteSelectedNodes()
                    end
                end, function()
                    if next(selections) and ui.button('clone') then
                        cloneSelectedNodes()
                    end
                end)

                ui.markdown('---')

                local function uiForNode(node)
                    nodeSectionOpen = ui.section('node', { open = nodeSectionOpen }, function()
                        ui.dropdown('type', node.type, { 'image', 'text', 'group', 'sound' }, {
                            onChange = function(newType)
                                if hasChildren(node) then -- Shallow only for now
                                    print("can't change type of a group that has children -- you must either detach or delete the children first!")
                                    return
                                end
                                node[node.type] = nil
                                node.type = newType
                                node[node.type] = NODE_TYPE_DEFAULTS[node.type]
                            end,
                        })

                        ui.box('tags-row', { flexDirection = 'row', alignItems = 'stretch' }, function()
                            ui.box('tags-input', { flex = 1 }, function()
                                node.tagsText = ui.textInput('tags', node.tagsText, {
                                    invalid = node.tagsText:match('^[%w ]*$') == nil,
                                    invalidText = 'tags must be separated by spaces, and can only contain letters or digits',
                                })
                            end)

                            if node.tagsText:match('^[%w ]*$') then
                                local tagsChanged = false
                                local newTags = {}
                                for tag in node.tagsText:gmatch('%S+') do
                                    if not node.tags[tag] then -- Tag added?
                                        tagsChanged = true
                                    end
                                    newTags[tag] = true
                                end
                                if not tagsChanged then
                                    for tag in pairs(node.tags) do
                                        if not newTags[tag] then -- Tag removed?
                                            tagsChanged = true
                                        end
                                    end
                                end
                                if tagsChanged then
                                    ui.box('tags-button', { flexDirection = 'row', marginLeft = 20, alignItems = 'flex-end' }, function()
                                        if ui.button('apply') then
                                            node.tags = newTags
                                            updateIndices(node.parentId, node.parentId, node)
                                        end
                                    end)
                                end
                            end
                        end)

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
                    end)

                    if node.type == 'image' then
                        typeSectionOpen = ui.section('image', { open = typeSectionOpen }, function()
                            node.image.url = ui.textInput('url', node.image.url)

                            local c = node.image.color
                            c.r, c.g, c.b, c.a = ui.colorPicker('color', c.r, c.g, c.b, c.a)

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
                        end)
                    end

                    if node.type == 'text' then
                        typeSectionOpen = ui.section('text', { open = typeSectionOpen }, function()
                            node.text.text = ui.textArea('text', node.text.text)

                            node.text.fontUrl = ui.textInput('font url', node.text.fontUrl)

                            node.text.fontSize = ui.slider('font size', node.text.fontSize, MIN_FONT_SIZE, MAX_FONT_SIZE)
                            node.text.fontSize = math.max(MIN_FONT_SIZE, math.min(node.text.fontSize, MAX_FONT_SIZE))

                            local c = node.text.color
                            c.r, c.g, c.b, c.a = ui.colorPicker('color', c.r, c.g, c.b, c.a)
                        end)
                    end

                    if node.type == 'sound' then
                        typeSectionOpen = ui.section('sound', { open = typeSectionOpen }, function()
                            if node.sound.sfxr then
                                local s = node.sound.sfxr

                                if ui.button('play') then
                                    getNodeProxy(node):play()
                                end

                                ui.markdown('### randomize')

                                uiRow('randomize-1', function()
                                    if ui.button('randomize') then
                                        getNodeProxy(node):randomize()
                                    end
                                end, function()
                                    if ui.button('mutate') then
                                        getNodeProxy(node):mutate()
                                    end
                                end, function()
                                    if ui.button('pickup') then
                                        getNodeProxy(node):randomPickup()
                                    end
                                end)

                                uiRow('randomize-2', function()
                                    if ui.button('laser') then
                                        getNodeProxy(node):randomLaser()
                                    end
                                end, function()
                                    if ui.button('explosion') then
                                        getNodeProxy(node):randomExplosion()
                                    end
                                end, function()
                                    if ui.button('powerup') then
                                        getNodeProxy(node):randomPowerup()
                                    end
                                end)

                                uiRow('randomize-3', function()
                                    if ui.button('hit') then
                                        getNodeProxy(node):randomHit()
                                    end
                                end, function()
                                    if ui.button('jump') then
                                        getNodeProxy(node):randomJump()
                                    end
                                end, function()
                                    if ui.button('blip') then
                                        getNodeProxy(node):randomBlip()
                                    end
                                end)

                                ui.markdown('### parameters')

                                s.repeatspeed = ui.slider('repeat speed', s.repeatspeed, 0, 1, { step = 0.01 })

                                local waveforms = {
                                    square = 0, sawtooth = 1, sine = 2, noise = 3,
                                    [0] = 'square', [1] = 'sawtooth', [2] = 'sine', [3] = 'noise',
                                }
                                local waveformIndex = waveforms[s.waveform]
                                waveformIndex = ui.dropdown('waveform', waveformIndex, { 'square', 'sawtooth', 'sine', 'noise' })
                                s.waveform = waveforms[waveformIndex]

                                uiRow('volume-master-sound', function()
                                    s.volume.master = ui.slider('volume master', s.volume.master, 0, 1, { step = 0.01 })
                                end, function()
                                    s.volume.sound = ui.slider('volume sound', s.volume.sound, 0, 1, { step = 0.01 })
                                end)

                                uiRow('envelope-attack-sustain', function()
                                    s.envelope.attack = ui.slider('envelope attack', s.envelope.attack, 0, 1, { step = 0.01 })
                                end, function()
                                    s.envelope.sustain = ui.slider('envelope sustain', s.envelope.sustain, 0, 1, { step = 0.01 })
                                end)
                                uiRow('envelope-punch-decay', function()
                                    s.envelope.punch = ui.slider('envelope punch', s.envelope.punch, 0, 1, { step = 0.01 })
                                end, function()
                                    s.envelope.decay = ui.slider('envelope decay', s.envelope.decay, 0, 1, { step = 0.01 })
                                end)

                                uiRow('frequency-start-min', function()
                                    s.frequency.start = ui.slider('frequency start', s.frequency.start, 0, 1, { step = 0.01 })
                                end, function()
                                    s.frequency.min = ui.slider('frequency min', s.frequency.min, 0, 1, { step = 0.01 })
                                end)
                                uiRow('frequency-slide-dslide', function()
                                    s.frequency.slide = ui.slider('frequency slide', s.frequency.slide, -1, 1, { step = 0.01 })
                                end, function()
                                    s.frequency.dslide = ui.slider('frequency dslide', s.frequency.dslide, -1, 1, { step = 0.01 })
                                end)

                                uiRow('change-amount-speed', function()
                                    s.change.amount = ui.slider('change amount', s.change.amount, -1, 1, { step = 0.01 })
                                end, function()
                                    s.change.speed = ui.slider('change speed', s.change.speed, 0, 1, { step = 0.01 })
                                end)

                                uiRow('duty-ratio-sweep', function()
                                    s.duty.ratio = ui.slider('duty ratio', s.duty.ratio, 0, 1, { step = 0.01 })
                                end, function()
                                    s.duty.sweep = ui.slider('duty sweep', s.duty.sweep, -1, 1, { step = 0.01 })
                                end)

                                uiRow('phaser-offset-sweep', function()
                                    s.phaser.offset = ui.slider('phaser offset', s.phaser.offset, -1, 1, { step = 0.01 })
                                end, function()
                                    s.phaser.sweep = ui.slider('phaser sweep', s.phaser.sweep, -1, 1, { step = 0.01 })
                                end)

                                uiRow('lowpass-cutoff-sweep', function()
                                    s.lowpass.cutoff = ui.slider('lowpass cutoff', s.lowpass.cutoff, 0, 1, { step = 0.01 })
                                end, function()
                                    s.lowpass.sweep = ui.slider('lowpass sweep', s.lowpass.sweep, -1, 1, { step = 0.01 })
                                end)
                                s.lowpass.resonance = ui.slider('lowpass resonance', s.lowpass.resonance, 0, 1, { step = 0.01 })

                                uiRow('highpass-cutoff-sweep', function()
                                    s.highpass.cutoff = ui.slider('highpass cutoff', s.highpass.cutoff, 0, 1, { step = 0.01 })
                                end, function()
                                    s.highpass.sweep = ui.slider('highpass sweep', s.highpass.sweep, -1, 1, { step = 0.01 })
                                end)

                                uiRow('vibrato-depth-speed', function()
                                    s.vibrato.depth = ui.slider('vibrato depth', s.vibrato.depth, 0, 1, { step = 0.01 })
                                end, function()
                                    s.vibrato.speed = ui.slider('vibrato speed', s.vibrato.speed, 0, 1, { step = 0.01 })
                                end)
                            end
                        end)
                    end

                    if node.type == 'group' then
                        ui.markdown('---')

                        ui.tabs('group tabs', function()
                            ui.tab('rules', function()
                                if ui.button('add rule') then
                                    local newIndex = #node.group.rules + 1
                                    node.group.rules[newIndex] = RULE_COMMON_DEFAULTS
                                    local newRule = node.group.rules[newIndex]
                                    newRule.id = uuid()

                                    newRule[newRule.action] = RULE_ACTION_DEFAULTS[newRule.action]
                                end

                                for i = 1, #node.group.rules do
                                    local rule = node.group.rules[i]
                                    ruleSectionOpen[rule.id] = ui.section(rule.kind .. ': ' .. getRuleDescription(rule), {
                                        id = rule.id,
                                        open = ruleSectionOpen[rule.id] == nil and true or ruleSectionOpen[rule.id],
                                    }, function()
                                        uiRow('kind-action', function()
                                            rule.kind = ui.dropdown('kind', rule.kind, { 'think' })
                                        end, function()
                                            ui.dropdown('action', rule.action, { 'code' }, {
                                                onChange = function(newAction)
                                                    rule[rule.action] = nil
                                                    rule.action = newAction
                                                    rule[rule.action] = RULE_ACTION_DEFAULTS[rule.action]
                                                end
                                            })
                                        end)

                                        ui.box('enabled-etc', { flexDirection = 'row', alignItems = 'center' }, function()
                                            ui.box('enabled', { width = 104, justifyContent = 'center' }, function()
                                                rule.enabled = ui.toggle('rule off', 'rule on', rule.enabled)
                                            end)

                                            ui.box('description', { flex = 1 }, function()
                                                rule.description = ui.textInput('description', rule.description, {
                                                    maxLength = MAX_RULE_DESCRIPTION_LENGTH,
                                                })
                                                rule.description = rule.description:sub(1, MAX_RULE_DESCRIPTION_LENGTH)
                                            end)
                                        end)


                                        if rule.action == 'code' then
                                            local edit = ui.codeEditor('code', rule.code.edited or rule.code.applied, {})
                                            if edit == rule.code.applied then
                                                rule.code.edited = nil
                                            else
                                                rule.code.edited = edit
                                            end
                                            uiRow('apply', function()
                                                if rule.code.edited then
                                                    ui.markdown('edited')
                                                else
                                                    ui.markdown('applied')
                                                end
                                            end, function()
                                                if rule.code.edited then
                                                    if ui.button('apply') then
                                                        rule.code.applied = rule.code.edited
                                                        rule.code.edited = nil
                                                    end
                                                end
                                            end)
                                        end
                                    end)
                                end
                            end)

                            ui.tab('children', function()
                                for childId in pairs(parentChildIndex[node.id] or {}) do
                                    local child = getNodeWithId(childId)
                                    if child then
                                        uiRow('child-' .. childId, function()
                                            ui.markdown(child.type)
                                        end, function()
                                            if ui.button('show') then
                                                secondarySelection = child.id
                                            end
                                        end, function()
                                            if ui.button('unlink') then
                                                local childTransform = getWorldSpace(child).transform
                                                child.x, child.y = childTransform:transformPoint(0, 0)
                                                child.rotation = getTransformRotation(childTransform)
                                                updateIndices(child.parentId, nil, child)
                                            end
                                        end)
                                    end
                                end
                            end)
                        end)
                    end
                end

                for id in pairs(selections) do
                    local node = getNodeWithId(id)
                    if node then
                        uiForNode(node)
                    end
                end

                for id in pairs(conflictingSelections) do
                    local node = getNodeWithId(id)
                    if node then
                        ui.box('locked-' .. id, { border = '1px solid yellow', padding = 2 }, function()
                            local player = share.players[share.locks[id]]
                            if player and player.me and player.me.username then
                                if player.me.photoUrl then
                                    ui.box('lock-description', { flexDirection = 'row' }, function()
                                        ui.box('locked-by', { marginRight = 10, justifyContent = 'center' }, function()
                                            ui.markdown('🔒 locked by')
                                        end)
                                        ui.box('lock-photo', { maxWidth = 16, maxHeight = 16, justifyContent = 'center' }, function()
                                            ui.image(player.me.photoUrl)
                                        end)
                                        ui.box('lock-username', { flex = 1, marginLeft = '8px', justifyContent = 'center' }, function()
                                            ui.markdown(player.me.username)
                                        end)
                                    end)
                                else
                                    ui.markdown('🔒 locked by ' .. player.username)
                                end
                            else
                                ui.markdown('🔒 locked by unknown')
                            end

                            ui.markdown('---')

                            local root = stateLib.new()
                            root:__autoSync(true)
                            root.node = node
                            root:__flush()
                            uiForNode(root.node)
                            if root:__diff(0) then
                                if player and player.me and player.me.username then
                                    print("can't edit this node because it is locked by " .. player.me.username)
                                else
                                    print("can't edit this node because it is locked by another user")
                                end
                            end
                        end)
                    end
                end
            end)

            ui.tab('world', function()
                local bgc = share.settings.backgroundColor
                ui.colorPicker('background color', bgc.r, bgc.g, bgc.b, 1, {
                    onChange = function(c)
                        client.send('setSetting', 'backgroundColor', c)
                    end,
                })

                ui.checkbox('smooth scale new images', share.settings.defaultSmoothScaling, {
                    onChange = function(v)
                        client.send('setSetting', 'defaultSmoothScaling', v)
                    end
                })

                uiSpacer()

                if ui.button('post world!') then
                    network.async(function()
                        castle.post.create {
                            message = 'A world we created!',
                            media = 'capture',
                            data = {
                                settings = share.settings,
                                nodes = cloneValue(share.nodes),
                            },
                        }
                    end)
                end
            end)

            ui.tab('help', function()
                ui.markdown([[
in edit world you can walk around the world, explore nodes placed by other people, or place your own nodes! **invite** friends through the 'Invite: ' link in the Castle bottom bar to collaborate.

### walking

use the W, A, S and D keys to walk around.

### creating nodes

to create a node, in the **'nodes' tab**, hit **'new'** and you will see an image appear in the center of your screen. this is a new node!

use the **'type' dropdown** to switch to a different type of node (such as text or group).

### editing nodes

to **select** an existing node, just **click** it. when you make a new node, it is already selected. you can change its **properties** in the 'nodes' tab in the sidebar.

- **images**: you can change the source **url** of the image, **crop** the image or change whether it scales **smooth**ly.
- **text**: you can change the **text** that is displayed, set its **font size** and **color**, or select a **source url** for the font used.
- **group**: you can see what children the group has and unlink children. to learn more about groups, check out the section on them below.

### moving nodes

with a node selected, press **G** to enter **grab mode** -- the node will move with your mouse cursor. press G again or click to exit grab mode.

similarly, **T** enters **resize mode** where you can use the mouse to change the node's width and height, and **R** enters **rotate mode** where you can change the node's rotation.

### groups

groups can contain other nodes as 'children'. when you move or rotate a group, its children move and rotate with it. this allows you to organize the world when there are a lot of nodes.

to add a node to a group, first select the node. then, right click on the group to select it as a **'secondary'** selection, shown as a **red** box around it (unlike the usual green box around a normal selection). then press P (for 'parent') to add the node as a child of the group, thus making the group the parent of that node.

to remove a node from its parent group, simply select it then press P with no secondary selection active.

### editing world properties

in the **'world' tab** you can edit **world-level** properties such as the **background color**.

### saving the world

in the 'world' tab, hit **'post world!'** to create a post storing the world. then you (or anyone!) can **open that post** to start a **new session** with the saved world.
                ]])
            end)
        end)
    end
end


--- CHANGING / CHANGED

local oldParentIds = {}

function client.changing(diff)
    if diff.nodes then
        for id, nodeDiff in pairs(diff.nodes) do
            if not (home.controlled and home.controlled[id]) then
                if nodeDiff.parentId then -- Save old parent id
                    local oldNode = getNodeWithId(id)
                    if oldNode and oldNode.parentId then
                        oldParentIds[id] = oldNode.parentId
                    end
                end
            end
        end
    end
end

function client.changed(diff)
    if diff.nodes then
        for id, nodeDiff in pairs(diff.nodes) do
            if not (home.controlled and home.controlled[id]) then
                local node = share.nodes[id]
                if nodeDiff.parentId then
                    updateIndices(oldParentIds[id], node.parentId, node)
                elseif nodeDiff.tags then
                    updateIndices(node.parentId, node.parentId, node)
                end
            end
        end
    end
    oldParentIds = {}
end