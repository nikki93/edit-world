local ui_utils = require 'common.ui_utils'
local ui = castle.ui


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
}


node_base.proxyMethods = setmetatable({}, {
    __index = function(self, k)
        return function()
            error("nodes of type '" .. self.__node.type .. "' do not have a `:" .. k .. "` method")
        end
    end,
})
node_base.proxyMetatable = { __index = node_base.proxyMethods }


--
-- Methods
--

function node_base.proxyMethods:getId()
    return self.__node.id
end

function node_base.proxyMethods:hasChildren()
    return self.__nodeManager:hasChildren(self.__node)
end


--
-- UI
--

local sectionOpen = true

function node_base.proxyMethods:ui(props)
    local node, nodeManager = self.__node, self.__nodeManager

    local function inside()
        -- Type
        ui.dropdown('type', node.type, { 'image', 'text', 'group', 'sound' }, {
            onChange = props.validateChange(function(newType)
                if newType ~= node.type then
                    if self:hasChildren() then
                        print("can't change type of a group that has children -- you must either detach or delete the children first!")
                        return
                    end
                    nodeManager:changeType(node, newType)
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
    end

    if props.surroundSection ~= false then
        sectionOpen = ui.section('node', { open = sectionOpen }, inside)
    else
        inside()
    end
end


return node_base