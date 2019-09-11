local node_base = require 'common.node_base'
local ui_utils = require 'common.ui_utils'
local ui = castle.ui
local resource_loader = require 'common.resource_loader'


local node_image = {}


node_image.DEFAULTS = {
    url = '',
    color = { r = 1, g = 1, b = 1, a = 1 },
    smoothScaling = true,
    crop = false,
    cropX = 0,
    cropY = 0,
    cropWidth = 32,
    cropHeight = 32,
}


node_image.proxyMethods = setmetatable({}, { __index = node_base.proxyMethods })
node_image.proxyMetatable = { __index = node_image.proxyMethods }


--
-- Draw
--

local theTransform = love.math.newTransform()
local theQuad = love.graphics and love.graphics.newQuad(0, 0, 32, 32, 32, 32)

function node_image.proxyMethods:draw(transform)
    local node = self.__node

    -- Image
    self.__imageHolder = resource_loader.loadImage(node.image.url)
    local image = self.__imageHolder.image

    -- Filter
    local filter = image:getFilter()
    if node.image.smoothScaling and filter == 'nearest' then
        image:setFilter('linear', 'linear')
    end
    if not node.image.smoothScaling and filter == 'linear' then
        image:setFilter('nearest', 'nearest')
    end

    -- Crop
    local imageWidth, imageHeight = image:getWidth(), image:getHeight()
    if node.image.crop then
        theQuad:setViewport(node.image.cropX, node.image.cropY, node.image.cropWidth, node.image.cropHeight, imageWidth, imageHeight)
    else
        theQuad:setViewport(0, 0, imageWidth, imageHeight, imageWidth, imageHeight)
    end
    local quadX, quadY, quadWidth, quadHeight = theQuad:getViewport()

    -- Color
    local color = node.image.color
    love.graphics.setColor(color.r, color.g, color.b, color.a)

    -- Transform
    theTransform:reset()
    theTransform:apply(transform)
    theTransform:translate(-0.5 * node.width, -0.5 * node.height):scale(node.width / quadWidth, node.height / quadHeight)
    love.graphics.draw(image, theQuad, theTransform)
end


--
-- UI
--

function node_image.proxyMethods:uiType(props)
    local node, nodeManager = self.__node, self.__nodeManager

    if type(self.__imageSectionOpen) ~= 'boolean' then
        self.__imageSectionOpen = true
    end
    self.__imageSectionOpen = ui.section('image', { open = self.__imageSectionOpen }, function()
        -- URL
        ui.textInput('url', node.image.url, {
            onChange = props.validateChange(function(newUrl)
                node.image.url = newUrl
            end),
        })

        -- Color
        local color = node.image.color
        ui.colorPicker('color', color.r, color.g, color.b, color.a, {
            onChange = props.validateChange(function(newColor)
                color.r, color.g, color.b, color.a = newColor.r, newColor.g, newColor.b, newColor.a
            end),
        })

        -- Smooth scaling, crop
        ui_utils.row('smooth-scaling-crop', function()
            ui.toggle('smooth scaling', 'smooth scaling', node.image.smoothScaling, {
                onToggle = props.validateChange(function(newSmoothScaling)
                    node.image.smoothScaling = newSmoothScaling
                end),
            })
        end, function()
            ui.toggle('crop', 'crop', node.image.crop, {
                onToggle = props.validateChange(function(newCrop)
                    node.image.crop = newCrop
                end),
            })
        end)
        if node.image.crop then
            ui_utils.row('crop-xy', function()
                ui.numberInput('crop x', node.image.cropX, {
                    onChange = props.validateChange(function(newCropX)
                        node.image.cropX = newCropX
                    end),
                })
            end, function()
                ui.numberInput('crop y', node.image.cropY, {
                    onChange = props.validateChange(function(newCropY)
                        node.image.cropY = newCropY
                    end),
                })
            end)
            ui_utils.row('crop-size', function()
                ui.numberInput('crop width', node.image.cropWidth, {
                    onChange = props.validateChange(function(newCropWidth)
                        node.image.cropWidth = newCropWidth
                    end),
                })
            end, function()
                ui.numberInput('crop height', node.image.cropHeight, {
                    onChange = props.validateChange(function(newCropHeight)
                        node.image.cropHeight = newCropHeight
                    end),
                })
            end)
            if ui.button('reset crop') then
                props.validateChange(function()
                    local image = node_image.imageFromUrl(node.image.url)
                    if image then
                        node.image.cropX, node.image.cropY = 0, 0
                        node.image.cropWidth, node.image.cropHeight = image:getDimensions()
                    end
                end)()
            end
        end
    end)
end


return node_image