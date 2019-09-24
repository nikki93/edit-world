local ui_utils = require 'common.ui_utils'
local ui = castle.ui
local math_utils = require 'common.math_utils'


local VARIABLE_VALUE_TYPE_ALLOWED = {
    ['nil'] = true,
    ['boolean'] = true,
    ['number'] = true,
    ['string'] = true,
    ['function'] = false,
    ['userdata'] = false,
    ['thread'] = false,
    ['table'] = true,
}


local node_base = {}


node_base.DEFAULTS = {
    type = 'image',
    tagsText = '',
    tags = {}, -- `tag` -> `true`
    parentId = nil,
    x = 0,
    y = 0,
    rotation = 0,
    depth = 100,
    width = 4,
    height = 4,
    variables = {},
}


node_base.proxyMethods = setmetatable({}, {
    __index = function(_, k)
        if k:match('^__') then
            return nil
        end
        return function(self)
            -- if type(self) == 'table' and self.__node then
            --     error("nodes of type '" .. self.__node.type .. "' do not have a `:" .. k .. "` method", 2)
            -- else
                error("this node does not have a `:" .. k .. "` method", 2)
            -- end
        end
    end,
})
node_base.proxyMetatable = { __index = node_base.proxyMethods }


--
-- Methods
--

-- Id

function node_base.proxyMethods:getId()
    return self.__node.id
end


-- Type

function node_base.proxyMethods:getType()
    return self.__node.type
end


-- Tags

function node_base.proxyMethods:hasTag(tag)
    assert(type(tag) == 'string', '`tag` must be a string')
    return self.__node.tags[tag] ~= nil
end

function node_base.proxyMethods:addTag(tag)
    assert(type(tag) == 'string', '`tag` must be a string')
    self.__nodeManager:addTag(self.__node, tag)
end

function node_base.proxyMethods:removeTag(tag)
    assert(type(tag) == 'string', '`tag` must be a string')
    self.__nodeManager:removeTag(self.__node, tag)
end


-- Parent / child

function node_base.proxyMethods:hasChildren()
    return self.__nodeManager:hasChildren(self.__node)
end

function node_base.proxyMethods:getChildWithId(childId)
    assert(type(childId) == 'string', '`childId` must be a string')
    return self.__nodeManager:getProxy(self.__nodeManager:getChildWithId(self.__node, childId))
end

function node_base.proxyMethods:getChildren()
    local result = {}
    self.__nodeManager:forEachChild(self.__node, function(childId, child)
        result[childId] = self.__nodeManager:getProxy(child)
    end)
    return result
end

function node_base.proxyMethods:getChildrenWithTag(tag)
    assert(type(tag) == 'string', '`tag` must be a string')
    local result = {}
    self.__nodeManager:forEachChildWithTag(self.__node, tag, function(childId, child)
        result[childId] = self.__nodeManager:getProxy(child)
    end)
    return result
end

function node_base.proxyMethods:getChildWithTag(tag)
    assert(type(tag) == 'string', '`tag` must be a string')
    local result, multipleFound = nil, false
    self.__nodeManager:forEachChildWithTag(self.__node, tag, function(childId, child)
        if result then
            multipleFound = true
            return false
        end
        result = self.__nodeManager:getProxy(child)
    end)
    if multipleFound then
        error("multiple children with tag '" .. tag .. "'")
    end
    return result
end


-- Random number generation

local randomGenerator = love.math.newRandomGenerator()

function node_base.proxyMethods:random(...)
    local node = self.__node
    randomGenerator:setState(node.rngState)
    local r = randomGenerator:random(...)
    node.rngState = randomGenerator:getState()
    return r
end

function node_base.proxyMethods:randomNormal(...)
    local node = self.__node
    randomGenerator:setState(node.rngState)
    local r = randomGenerator:randomNormal(...)
    node.rngState = randomGenerator:getState()
    return r
end


-- Space

function node_base.proxyMethods:getX()
    return self.__node.x
end

function node_base.proxyMethods:setX(x)
    assert(type(x) == 'number', '`x` must be a number')
    self.__node.x = x
end

function node_base.proxyMethods:getY()
    return self.__node.y
end

function node_base.proxyMethods:setY(y)
    assert(type(y) == 'number', '`y` must be a number')
    self.__node.y = y
end

function node_base.proxyMethods:getPosition()
    local node = self.__node
    return node.x, node.y
end

function node_base.proxyMethods:setPosition(x, y)
    assert(type(x) == 'number', '`x` must be a number')
    assert(type(y) == 'number', '`y` must be a number')
    local node = self.__node
    node.x, node.y = x, y
end

function node_base.proxyMethods:move(deltaX, deltaY)
    assert(type(deltaX) == 'number', '`deltaX` must be a number')
    assert(type(deltaY) == 'number', '`deltaY` must be a number')
    local node = self.__node
    node.x, node.y = node.x + deltaX, node.y + deltaY
end

function node_base.proxyMethods:getRotation()
    return self.__node.rotation
end

function node_base.proxyMethods:setRotation(rotation)
    assert(type(rotation) == 'number', '`rotation` must be a number')
    self.__node.rotation = math_utils.sanitizeAngle(rotation)
end

function node_base.proxyMethods:rotate(deltaRotation)
    assert(type(deltaRotation) == 'number', '`deltaRotation` must be a number')
    local node = self.__node
    node.rotation = math_utils.sanitizeAngle(node.rotation + deltaRotation)
end

function node_base.proxyMethods:getDepth()
    return self.__node.depth
end

function node_base.proxyMethods:setDepth(depth)
    assert(type(depth) == 'number', '`depth` must be a number')
    self.__node.depth = depth
end

function node_base.proxyMethods:getWidth()
    return self.__node.width
end

function node_base.proxyMethods:setWidth(width)
    assert(type(width) == 'number', '`width` must be a number')
    self.__node.width = width
end

function node_base.proxyMethods:getHeight()
    return self.__node.height
end

function node_base.proxyMethods:setHeight(height)
    assert(type(height) == 'number', '`height` must be a number')
    self.__node.height = height
end

function node_base.proxyMethods:getSize()
    local node = self.__node
    return node.width, node.height
end

function node_base.proxyMethods:setSize(width, height)
    assert(type(width) == 'number', '`width` must be a number')
    assert(type(height) == 'number', '`height` must be a number')
    local node = self.__node
    node.width, node.height = width, height
end


-- Variables

function node_base.proxyMethods:get(variableName, ...)
    if variableName == nil then
        return nil
    end
    assert(type(variableName) == 'string', '`variableName` must be a string')
    return self.__node.variables[variableName], self:get(...)
end

function node_base.proxyMethods:set(variableName, value, ...)
    if variableName == nil then
        return
    end
    assert(type(variableName) == 'string', '`variableName` must be a string')
    local valueType = type(value)
    assert(VARIABLE_VALUE_TYPE_ALLOWED[valueType], "variable values of type '" .. valueType .. "' are not allowed")
    self.__node.variables[variableName] = value
    self:set(...)
end


--
-- UI
--

function node_base.proxyMethods:uiNodePart(props)
    local node, nodeManager = self.__node, self.__nodeManager

    self.__nodeSectionOpen = ui.section('node', {
        open = self.__nodeSectionOpen == nil and true or self.__nodeSectionOpen,
    }, function()
        -- Type
        ui.dropdown('type', node.type, { 'image', 'text', 'group', 'sound' }, {
            onChange = props.validateChange(function(newType)
                if newType ~= node.type then
                    if self:hasChildren() then
                        print("can't change type of a group that has children -- you must either detach or delete the children first!")
                        return
                    end
                    nodeManager:setType(node, newType)
                end
            end),
        })

        -- Tags
        ui.box('tags-row', { flexDirection = 'row', alignItems = 'stretch' }, function()
            ui.box('tags-input', { flex = 1 }, function()
                ui.textInput('tags', node.tagsText, {
                    invalid = node.tagsText:match('^[%w ]*$') == nil,
                    invalidText = 'tags must be separated by spaces, and can only contain letters or digits',
                    onChange = props.validateChange(function(newTagsText)
                        node.tagsText = newTagsText
                    end),
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
                            nodeManager:setTags(node, newTags)
                        end
                    end)
                end
            end
        end)

        -- Position
        ui_utils.row('position', function()
            ui.numberInput('x', node.x, {
                onChange = props.validateChange(function(newX)
                    node.x = newX
                end),
            })
        end, function()
            ui.numberInput('y', node.y, {
                onChange = props.validateChange(function(newY)
                    node.y = newY
                end),
            })
        end)

        -- Rotation, depth
        ui_utils.row('rotation-depth', function()
            ui.numberInput('rotation (degrees)', node.rotation * 180 / math.pi, {
                onChange = props.validateChange(function(newRotation)
                    node.rotation = newRotation * math.pi / 180
                end),
            })
        end, function()
            ui.numberInput('depth', node.depth, {
                onChange = props.validateChange(function(newDepth)
                    node.depth = newDepth
                end),
            })
        end)

        -- Size
        ui_utils.row('size', function()
            ui.numberInput('width', node.width, {
                onChange = props.validateChange(function(newWidth)
                    node.width = newWidth
                end),
            })
        end, function()
            ui.numberInput('height', node.height, {
                onChange = props.validateChange(function(newHeight)
                    node.height = newHeight
                end),
            })
        end)
    end)
end

function node_base.proxyMethods:ui(props)
    local node = self.__node

    local oldType = node.type

    self:uiNodePart(props)

    if node.type == oldType then -- Don't call stale `:uiTypePart` method if type changed
        self:uiTypePart(props)
    end
end


return node_base