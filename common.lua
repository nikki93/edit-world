cs = require 'https://raw.githubusercontent.com/castle-games/share.lua/623c500de3cbfd544db9e6f2bdcd03b5b7e6f377/cs.lua'

uuid = require 'https://raw.githubusercontent.com/Tieske/uuid/75f84281f4c45838f59fc2c6f893fa20e32389b6/src/uuid.lua'
uuid.seed()

serpent = require 'https://raw.githubusercontent.com/pkulchenko/serpent/879580fb21933f63eb23ece7d60ba2349a8d2848/src/serpent.lua'

sfxr = require 'https://raw.githubusercontent.com/nucular/sfxrlua/27511554ab63b834a8d8b34437c4ba5f0f589fdf/sfxr.lua'

marshal = require 'marshal'


--- VALUE UTILS

function cloneValue(t)
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


--- CONSTANTS

G = 32              -- Grid unit size

WALK_SPEED = 6 * G

CAMERA_GUTTER = 120

MIN_FONT_SIZE, MAX_FONT_SIZE = 8, 72

NODE_COMMON_DEFAULTS = {
    type = 'image',
    tagsText = '',
    tags = {}, -- `tag` -> `true`
    parentId = nil,
    x = 0,
    y = 0,
    rotation = 0,
    depth = 0,
    width = 4 * G,
    height = 4 * G,
}

NODE_TYPE_DEFAULTS = {
    image = {
        url = 'https://github.com/nikki93/edit-world/raw/66e4850578fd46cbb9f3c1db30611981f26906e5/checkerboard.png',
        color = { r = 1, g = 1, b = 1, a = 1 },
        smoothScaling = true,
        crop = false,
        cropX = 0,
        cropY = 0,
        cropWidth = 32,
        cropHeight = 32,
    },
    text = {
        text = 'type some\ntext here!',
        fontUrl = '',
        fontSize = 14,
        color = { r = 0, g = 0, b = 0, a = 1 },
    },
    sound = {
        sfxr = cloneValue(sfxr.newSound()),
        url = nil,
    },
    group = {
        childrenIds = {}, -- `childId` -> `true`
        tagIndices = {}, -- `tag` -> `childId` -> `true`
        rules = {},
    },
}

SETTINGS_DEFAULTS = {
    backgroundColor = { r = 1, g = 0.98, b = 0.98 },
    defaultSmoothScaling = true,
}

RULE_COMMON_DEFAULTS = {
    enabled = true,
    kind = 'think',
    action = 'code',
    description = '',
}

RULE_ACTION_DEFAULTS = {
    code = {
        edited = nil,
        applied = '',
    },
}

RULE_DESCRIPTION_DEFAULTS = {
    code = 'run code',
}

MAX_RULE_DESCRIPTION_LENGTH = 32


--- GRAPHICS UTILS

if love.graphics then
    -- `love.graphics.stacked([arg], func)` calls `func` between `love.graphics.push([arg])` and
    -- `love.graphics.pop()` while being resilient to errors
    function love.graphics.stacked(argOrFunc, funcOrNil)
        love.graphics.push(funcOrNil and argOrFunc)
        local succeeded, err = pcall(funcOrNil or argOrFunc)
        love.graphics.pop()
        if not succeeded then
            error(err, 0)
        end
    end
end


--- COMMON LOGIC

function updateTagIndex(parent, node, newTags)
    if not (parent and parent.type == 'group') then
        return
    end
    if node.tags ~= newTags then
        for tag in pairs(node.tags) do
            if not newTags[tag] then
                local tagIndex = parent.group.tagIndices[tag]
                if tagIndex then
                    tagIndex[node.id] = nil
                    local tagIndexEmpty = true
                    for id in pairs(tagIndex) do
                        tagIndexEmpty = false
                        break
                    end
                    if tagIndexEmpty then
                        parent.group.tagIndices[tag] = nil
                    end
                end
            end
        end
    end
    for tag in pairs(newTags) do
        local tagIndex = parent.group.tagIndices[tag]
        if not tagIndex then
            tagIndex = {}
            parent.group.tagIndices[tag] = tagIndex
        end
        tagIndex[node.id] = true
    end
end

function addToGroup(parent, child)
    if parent and parent.type == 'group' then
        child.parentId = parent.id
        parent.group.childrenIds[child.id] = true
        updateTagIndex(parent, child, child.tags)
    end
end

function removeFromGroup(parent, child)
    if parent and child.parentId == parent.id then
        child.parentId = nil
        parent.group.childrenIds[child.id] = nil
        updateTagIndex(parent, child, {})
    end
end

function getRuleDescription(rule)
    return rule.description == '' and RULE_DESCRIPTION_DEFAULTS[rule.action] or rule.description
end

do
    local cache = {}

    local env = setmetatable({
        print = print,
        ipairs = ipairs,
        next = next,
        pairs = pairs,
        pcall = pcall,
        tonumber = tonumber,
        tostring = tostring,
        type = type,
        unpack = unpack,
        coroutine = { create = coroutine.create, resume = coroutine.resume,
            running = coroutine.running, status = coroutine.status,
            wrap = coroutine.wrap },
        string = { byte = string.byte, char = string.char, find = string.find,
            format = string.format, gmatch = string.gmatch, gsub = string.gsub,
            len = string.len, lower = string.lower, match = string.match,
            rep = string.rep, reverse = string.reverse, sub = string.sub,
            upper = string.upper },
        table = { insert = table.insert, maxn = table.maxn, remove = table.remove,
            sort = table.sort },
        math = { abs = math.abs, acos = math.acos, asin = math.asin,
            atan = math.atan, atan2 = math.atan2, ceil = math.ceil, cos = math.cos,
            cosh = math.cosh, deg = math.deg, exp = math.exp, floor = math.floor,
            fmod = math.fmod, frexp = math.frexp, huge = math.huge,
            ldexp = math.ldexp, log = math.log, log10 = math.log10, max = math.max,
            min = math.min, modf = math.modf, pi = math.pi, pow = math.pow,
            rad = math.rad, random = math.random, sin = math.sin, sinh = math.sinh,
            sqrt = math.sqrt, tan = math.tan, tanh = math.tanh },
        os = { clock = os.clock, difftime = os.difftime, time = os.time },
        love = { math = love.math },
    }, {
        __newindex = function(t, k)
            error("global variable '" .. k .. "' not allowed!", 2)
        end,
    })

    function compileCode(code, desc)
        local cached = cache[code]
        if not cached then
            cached = {}
            cache[code] = cached
            local chunk, err = load(code, desc, 't', env)
            if chunk then
                cached.func = chunk()
            else
                cached.err = err
            end
        end
        return cached.func, cached.err
    end
end

do
    local nodeProxyIndex = {}


    function nodeProxyIndex:getId()
        return self.node.id
    end

    function nodeProxyIndex:getType()
        return self.node.type
    end

    function nodeProxyIndex:getChildren()
        local node = self.node
        if node.type ~= 'group' then
            return {}
        end
        local children = {}
        local getNodeWithId = self.getNodeWithId
        for childId in pairs(node.group.childrenIds) do
            children[childId] = getNodeProxy(getNodeWithId(childId), getNodeWithId)
        end
        return children
    end

    function nodeProxyIndex:getChild(childId)
        local node = self.node
        if node.type ~= 'group' then
            return nil
        end
        local getNodeWithId = self.getNodeWithId
        if node.group.childrenIds[childId] then
            return getNodeProxy(getNodeWithId(childId), getNodeWithId)
        end
    end

    function nodeProxyIndex:getChildrenWithTag(tag)
        local node = self.node
        if node.type ~= 'group' then
            return {}
        end
        local tagIndex = node.group.tagIndices[tag]
        if not tagIndex then
            return {}
        end
        local children = {}
        local getNodeWithId = self.getNodeWithId
        for childId in pairs(tagIndex) do
            children[childId] = getNodeProxy(getNodeWithId(childId), getNodeWithId)
        end
        return children
    end

    function nodeProxyIndex:getChildWithTag(tag)
        local node = self.node
        if node.type ~= 'group' then
            return nil
        end
        local tagIndex = node.group.tagIndices[tag]
        if not tagIndex then
            return nil
        end
        local child = nil
        local getNodeWithId = self.getNodeWithId
        for childId in pairs(tagIndex) do
            if child then
                error("multiple children with tag '" .. tag .. "'")
            else
                child = getNodeProxy(getNodeWithId(childId), getNodeWithId)
            end
        end
        return child
    end


    function nodeProxyIndex:getPosition()
        local node = self.node
        return node.x, node.y
    end

    function nodeProxyIndex:setPosition(x, y)
        assert(type(x) == 'number', '`x` must be a number')
        assert(type(y) == 'number', '`y` must be a number')
        local node = self.node
        node.x, node.y = x, y
    end

    function nodeProxyIndex:translate(x, y)
        assert(type(x) == 'number', '`x` must be a number')
        assert(type(y) == 'number', '`y` must be a number')
        local node = self.node
        node.x, node.y = node.x + x, node.y + y
    end

    function nodeProxyIndex:getX()
        return self.node.x
    end

    function nodeProxyIndex:setX(x)
        assert(type(x) == 'number', '`x` must be a number')
        self.node.x = x
    end

    function nodeProxyIndex:getY()
        return self.node.y
    end

    function nodeProxyIndex:setY(y)
        assert(type(y) == 'number', '`y` must be a number')
        self.node.y = y
    end

    function nodeProxyIndex:getRotation()
        return self.node.rotation
    end

    function nodeProxyIndex:setRotation(rotation)
        assert(type(rotation) == 'number', '`rotation` must be a number')
        self.node.rotation = rotation
    end

    function nodeProxyIndex:rotate(rotation)
        assert(type(rotation) == 'number', '`rotation` must be a number')
        local node = self.node
        node.rotation = node.rotation + rotation
    end

    function nodeProxyIndex:getDepth()
        return self.node.depth
    end

    function nodeProxyIndex:setDepth(depth)
        assert(type(depth) == 'number', '`depth` must be a number')
        self.node.depth = depth
    end

    function nodeProxyIndex:getSize()
        local node = self.node
        return node.width, node.height
    end

    function nodeProxyIndex:setSize(width, height)
        assert(type(width) == 'number', '`width` must be a number')
        assert(type(height) == 'number', '`height` must be a number')
        local node = self.node
        node.width, node.height = width, height
    end

    function nodeProxyIndex:getWidth()
        return self.node.width
    end

    function nodeProxyIndex:setWidth(width)
        assert(type(width) == 'number', '`width` must be a number')
        self.node.width = width
    end

    function nodeProxyIndex:getHeight()
        return self.node.height
    end

    function nodeProxyIndex:setHeight(height)
        assert(type(height) == 'number', '`height` must be a number')
        self.node.height = height
    end


    function nodeProxyIndex:getColor()
        local node = self.node
        assert(node.type == 'text' or node.type == 'image', 'node must be an image or a text')
        local c = node[node.type].color
        return c.r, c.g, c.b, c.a
    end

    function nodeProxyIndex:setColor(r, g, b, a)
        local node = self.node
        assert(node.type == 'text' or node.type == 'image', 'node must be an image or a text')
        assert(type(r) == 'number', '`r` must be a number')
        assert(type(g) == 'number', '`g` must be a number')
        assert(type(b) == 'number', '`b` must be a number')
        assert(type(a) == 'number' or type(a) == 'nil', '`a` must either be a number or left out')
        local c = node[node.type].color
        c.r, c.g, c.b, c.a = r, g, b, a or 1
    end


    function nodeProxyIndex:getUrl()
        assert(self.node.type == 'image', 'node must be an image')
        return self.node.image.url
    end

    function nodeProxyIndex:setUrl(url)
        assert(self.node.type == 'image', 'node must be an image')
        assert(type(url) == 'string', '`url` must be a string')
        self.node.image.url = url
    end

    function nodeProxyIndex:getSmoothScaling()
        assert(self.node.type == 'image', 'node must be an image')
        return self.node.image.smoothScaling
    end

    function nodeProxyIndex:setSmoothScaling(smoothScaling)
        assert(self.node.type == 'image', 'node must be an image')
        assert(type(smoothScaling) == 'boolean', '`smoothScaling` must be a boolean')
        self.node.image.smoothScaling = smoothScaling
    end

    function nodeProxyIndex:getCrop()
        assert(self.node.type == 'image', 'node must be an image')
        return self.node.image.crop
    end

    function nodeProxyIndex:setCrop(crop)
        assert(self.node.type == 'image', 'node must be an image')
        assert(type(crop) == 'boolean', '`crop` must be a boolean')
        self.node.image.crop = crop
    end

    function nodeProxyIndex:getCropRect()
        assert(self.node.type == 'image', 'node must be an image')
        local image = self.node.image
        return image.cropX, image.cropY, image.cropWidth, image.cropHeight
    end

    function nodeProxyIndex:setCropRect(cropX, cropY, cropWidth, cropHeight)
        assert(self.node.type == 'image', 'node must be an image')
        assert(type(cropX) == 'number', '`cropX` must be a number')
        assert(type(cropY) == 'number', '`cropY` must be a number')
        assert((type(cropWidth) == 'number' and type(cropHeight) == 'number') or (type(cropWidth) == 'nil' and type(cropHeight) == 'nil'),
            '`cropWidth` and `cropHeight` must either be both numbers or both left out')
        local image = self.node.image
        image.cropX, image.cropY = cropX, cropY
        if cropWidth and cropHeight then
            image.cropWidth, image.cropHeight = cropWidth, cropHeight
        end
    end

    function nodeProxyIndex:getCropX()
        assert(self.node.type == 'image', 'node must be an image')
        return self.node.image.cropX
    end

    function nodeProxyIndex:setCropX(cropX)
        assert(self.node.type == 'image', 'node must be an image')
        assert(type(cropX) == 'number', '`cropX` must be a number')
        self.node.image.cropX = cropX
    end

    function nodeProxyIndex:getCropY()
        assert(self.node.type == 'image', 'node must be an image')
        return self.node.image.cropY
    end

    function nodeProxyIndex:setCropY(cropY)
        assert(self.node.type == 'image', 'node must be an image')
        assert(type(cropY) == 'number', '`cropY` must be a number')
        self.node.image.cropY = cropY
    end

    function nodeProxyIndex:getCropWidth()
        assert(self.node.type == 'image', 'node must be an image')
        return self.node.image.cropWidth
    end

    function nodeProxyIndex:setCropWidth(cropWidth)
        assert(self.node.type == 'image', 'node must be an image')
        assert(type(cropWidth) == 'number', '`cropWidth` must be a number')
        self.node.image.cropWidth = cropWidth
    end

    function nodeProxyIndex:getCropHeight()
        assert(self.node.type == 'image', 'node must be an image')
        return self.node.image.cropHeight
    end

    function nodeProxyIndex:setCropHeight(cropHeight)
        assert(self.node.type == 'image', 'node must be an image')
        assert(type(cropHeight) == 'number', '`cropHeight` must be a number')
        self.node.image.cropHeight = cropHeight
    end


    function nodeProxyIndex:getText(text)
        assert(self.node.type == 'text', 'node must be a text')
        return self.node.text.text
    end

    function nodeProxyIndex:setText(text)
        assert(self.node.type == 'text', 'node must be a text')
        self.node.text.text = tostring(text)
    end

    function nodeProxyIndex:getFontUrl()
        assert(self.node.type == 'text', 'node must be a text')
        return self.node.text.fontUrl
    end

    function nodeProxyIndex:setFontUrl(fontUrl)
        assert(self.node.type == 'text', 'node must be a text')
        assert(type(fontUrl) == 'string', '`fontUrl` must be a string')
        self.node.text.fontUrl = fontUrl
    end

    function nodeProxyIndex:getFontSize()
        assert(self.node.type == 'text', 'node must be a text')
        return self.node.text.fontSize
    end

    function nodeProxyIndex:setFontSize(fontSize)
        assert(self.node.type == 'text', 'node must be a text')
        assert(type(fontSize) == 'number', '`fontSize` must be a number')
        self.node.text.fontSize = math.max(MIN_FONT_SIZE, math.min(fontSize, MAX_FONT_SIZE))
    end


    do
        local cache = {}
        function nodeProxyIndex:play()
            local node = self.node
            assert(node.type == 'sound', 'node must be a sound')
            local sound = node.sound
            if sound.sfxr then
                local marshalled = marshal.encode(cloneValue(sound.sfxr))
                local cached = cache[marshalled]
                if not cached then
                    cached = {}
                    cache[marshalled] = cached
                    local sfx = sfxr.newSound()
                    for memberName, memberValue in pairs(sound.sfxr) do
                        if type(memberValue) == 'table' or type(memberValue) == 'userdata' then
                            local t = sfx[memberName]
                            for k, v in pairs(memberValue) do
                                t[k] = v
                            end
                        else
                            assert(type(sfx[memberName]) == type(memberValue), 'internal error: type mismatch between sfxr parameters')
                            sfx[memberName] = memberValue
                        end
                    end
                    cached.source = love.audio.newSource(sfx:generateSoundData())
                end
                cached.source:clone():play()
            end
        end
    end

    do
        local methodNames = {
            'randomize', 'mutate', 'randomPickup', 'randomLaser', 'randomExplosion',
            'randomPowerup', 'randomHit', 'randomJump', 'randomBlip',
        }
        for _, methodName in ipairs(methodNames) do
            nodeProxyIndex[methodName] = function(self)
                local node = self.node
                assert(node.type == 'sound', 'node must be a sound')
                local sound = node.sound
                assert(sound.sfxr, 'node must be an sfxr sound')
                local sfx = sfxr.newSound()
                sfx[methodName](sfx)
                sound.sfxr = cloneValue(sfx)
            end
        end
    end


    local nodeProxyMeta = {
        __index = nodeProxyIndex,
        __newindex = function(t, k)
            error("setting member '" .. k .. "' of node not allowed", 2)
        end,
     }

    function getNodeProxy(node, getNodeWithId)
        if node == nil then
            return nil
        end
        return setmetatable({
            node = node,
            getNodeWithId = getNodeWithId,
        }, nodeProxyMeta)
    end
end

do
    local cache = {}

    local lastErrPrintTime = {}

    function runThinkRules(node, getNodeWithId)
        local dt = love.timer.getDelta()

        if node.type == 'group' then
            for i = 1, #node.group.rules do
                local rule = node.group.rules[i]
                if rule.enabled and rule.kind == 'think' then
                    if rule.action == 'code' then
                        local err

                        local cached = cache[rule.code.applied]
                        if not cached then
                            cached = {}
                            cache[rule.code.applied] = cached
                            local fullCode = 'return function(node, dt)\n' .. rule.code.applied .. '\nend'
                            cached.compiled, err = compileCode(fullCode, getRuleDescription(rule))
                        end
                        local compiled = cached.compiled
                        if compiled then
                            local succeeded
                            succeeded, err = pcall(compiled, getNodeProxy(node, getNodeWithId), dt)
                        end

                        if err then
                            local time = love.timer.getTime()
                            if not lastErrPrintTime[err] or time - lastErrPrintTime[err] > 1 then
                                print(err)
                                lastErrPrintTime[err] = time
                            end
                        end
                    end
                end
            end
        end
    end
end