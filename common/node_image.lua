local node_base = require 'common.node_base'
local ui_utils = require 'common.ui_utils'
local ui = castle.ui
local resource_loader = require 'common.resource_loader'


local node_image = {}


node_image.DEFAULTS = {
    url = '',
    color = { r = 1, g = 1, b = 1, a = 1 },
    fitMode = 'contain',
    smoothScaling = false,
    crop = false,
    cropX = 0,
    cropY = 0,
    cropWidth = 32,
    cropHeight = 32,
}


node_image.proxyMethods = setmetatable({}, { __index = node_base.proxyMethods })
node_image.proxyMetatable = { __index = node_image.proxyMethods }


--
-- Methods
--

function node_image.proxyMethods:getUrl()
    return self.__node.image.url
end

function node_image.proxyMethods:setUrl(url)
    assert(type(url) == 'string', '`url` must be a string')
    self.__node.image.url = url
end

function node_image.proxyMethods:getColor()
    local color = self.__node.image.color
    return color.r, color.g, color.b, color.a
end

function node_image.proxyMethods:setColor(r, g, b, a)
    assert(type(r) == 'number', '`r` must be a number')
    assert(type(g) == 'number', '`g` must be a number')
    assert(type(b) == 'number', '`b` must be a number')
    assert(type(a) == 'number' or type(a) == 'nil', '`a` must either be a number or left out')
    local color = self.__node.image.color
    color.r, color.g, color.b, color.a = r, g, b, a
end

function node_image.proxyMethods:getSmoothScaling()
    return self.__node.image.smoothScaling
end

function node_image.proxyMethods:setSmoothScaling(smoothScaling)
    assert(type(smoothScaling) == 'boolean', '`smoothScaling` must be a boolean')
    self.__node.image.smoothScaling = smoothScaling
end

function node_image.proxyMethods:getFitMode()
    return self.__node.image.fitMode
end

function node_image.proxyMethods:setFitMode(fitMode)
    assert(type(fitMode) == 'string', '`fitMode` must be a string')
    self.__node.image.fitMode = fitMode
end

function node_image.proxyMethods:getCrop()
    return self.__node.image.crop
end

function node_image.proxyMethods:setCrop(crop)
    assert(type(crop) == 'boolean', '`crop` must be a boolean')
    self.__node.image.crop = crop
end

function node_image.proxyMethods:getCropRect()
    local image = self.__node.image
    return image.cropX, image.cropY, image.cropWidth, image.cropHeight
end

function node_image.proxyMethods:setCropRect(cropX, cropY, cropWidth, cropHeight)
    assert(type(cropX) == 'number', '`cropX` must be a number')
    assert(type(cropY) == 'number', '`cropY` must be a number')
    assert((type(cropWidth) == 'number' and type(cropHeight) == 'number') or (type(cropWidth) == 'nil' and type(cropHeight) == 'nil'),
        '`cropWidth` and `cropHeight` must either be both numbers or both left out')
    local image = self.__node.image
    image.cropX, image.cropY = cropX, cropY
    if cropWidth and cropHeight then
        image.cropWidth, image.cropHeight = cropWidth, cropHeight
    end
end

function node_image.proxyMethods:getCropX()
    return self.__node.image.cropX
end

function node_image.proxyMethods:setCropX(cropX)
    assert(type(cropX) == 'number', '`cropX` must be a number')
    self.__node.image.cropX = cropX
end

function node_image.proxyMethods:getCropY()
    return self.__node.image.cropY
end

function node_image.proxyMethods:setCropY(cropY)
    assert(type(cropY) == 'number', '`cropY` must be a number')
    self.__node.image.cropY = cropY
end

function node_image.proxyMethods:getCropWidth()
    return self.__node.image.cropWidth
end

function node_image.proxyMethods:setCropWidth(cropWidth)
    assert(type(cropWidth) == 'number', '`cropWidth` must be a number')
    self.__node.image.cropWidth = cropWidth
end

function node_image.proxyMethods:getCropHeight()
    return self.__node.image.cropHeight
end

function node_image.proxyMethods:setCropHeight(cropHeight)
    assert(type(cropHeight) == 'number', '`cropHeight` must be a number')
    self.__node.image.cropHeight = cropHeight
end


--
-- Draw
--

local theTransform = love.math.newTransform()
local theQuad = love.graphics and love.graphics.newQuad(0, 0, 32, 32, 32, 32)

function node_image.proxyMethods:draw(transform)
    local node = self.__node

    -- Drawable
    local filter = node.image.smoothScaling and 'linear' or 'nearest'
    self.__imageHolder = resource_loader.loadImage(node.image.url, filter)
    local drawableImage = self.__imageHolder.image

    -- Crop
    local imageWidth, imageHeight = drawableImage:getWidth(), drawableImage:getHeight()
    if node.image.crop then
        theQuad:setViewport(node.image.cropX, node.image.cropY, node.image.cropWidth, node.image.cropHeight, imageWidth, imageHeight)
    else
        theQuad:setViewport(0, 0, imageWidth, imageHeight, imageWidth, imageHeight)
    end
    local quadX, quadY, quadWidth, quadHeight = theQuad:getViewport()

    -- Color
    local color = node.image.color
    love.graphics.setColor(color.r, color.g, color.b, color.a)

    -- Scale
    local scaleX, scaleY = node.width / quadWidth, node.height / quadHeight
    if node.image.fitMode == 'contain' then
        scaleX = math.min(scaleX, scaleY)
        scaleY = scaleX
    end

    -- Transform
    theTransform:reset()
    theTransform:apply(transform)
    theTransform:scale(scaleX, scaleY):translate(-0.5 * quadWidth, -0.5 * quadHeight)

    -- Draw!
    love.graphics.draw(drawableImage, theQuad, theTransform)
end


--
-- UI
--

function node_image.proxyMethods:uiTypePart(props)
    local node = self.__node

    self.__imageSectionOpen = ui.section('image', {
        open = self.__imageSectionOpen == nil and true or self.__imageSectionOpen,
    }, function()
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

        -- Fit mode
        ui.dropdown('fit mode', node.image.fitMode, { 'contain', 'stretch' }, {
            onChange = props.validateChange(function(newFitMode)
                node.image.fitMode = newFitMode
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
                    local drawableImage = resource_loader.loadImage(node.image.url).image
                    if drawableImage then
                        node.image.cropX, node.image.cropY = 0, 0
                        node.image.cropWidth, node.image.cropHeight = drawableImage:getDimensions()
                    end
                end)()
            end
        end
    end)
end


return node_image