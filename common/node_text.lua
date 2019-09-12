local resource_loader = require 'common.resource_loader'
local node_base = require 'common.node_base'
local ui = castle.ui


local MIN_FONT_SIZE, MAX_FONT_SIZE = 8, 72
local FONT_PIXELS_PER_UNIT = 32
local ALIGNS = { 'left', 'right', 'center', 'justify' }


local node_text = {}


node_text.DEFAULTS = {
    text = 'type some\ntext here!',
    fontUrl = '',
    fontSize = 14,
    color = { r = 0, g = 0, b = 0, a = 1 },
    align = 'left',
}

node_text.proxyMethods = setmetatable({}, { __index = node_base.proxyMethods })
node_text.proxyMetatable = { __index = node_text.proxyMethods }


--
-- Methods
--

function node_text.proxyMethods:getText()
    return self.__node.text.text
end

function node_text.proxyMethods:setText(text)
    assert(type(text) == 'string', '`text` must be a string')
    self.__node.text.text = text
end

function node_text.proxyMethods:getFontUrl()
    return self.__node.text.fontUrl
end

function node_text.proxyMethods:setFontUrl(fontUrl)
    assert(type(fontUrl) == 'string', '`fontUrl` must be a string')
    self.__node.text.fontUrl = fontUrl
end

function node_text.proxyMethods:getFontSize()
    return self.__node.text.fontSize
end

function node_text.proxyMethods:setFontSize(fontSize)
    assert(type(fontSize) == 'number', '`fontSize` must be a number')
    self.__node.text.fontSize = math.floor(fontSize)
end

function node_text.proxyMethods:getColor()
    local color = self.__node.text.color
    return color.r, color.g, color.b, color.a
end

function node_text.proxyMethods:setColor(r, g, b, a)
    assert(type(r) == 'number', '`r` must be a number')
    assert(type(g) == 'number', '`g` must be a number')
    assert(type(b) == 'number', '`b` must be a number')
    assert(type(a) == 'number' or type(a) == 'nil', '`a` must either be a number or left out')
    local color = self.__node.text.color
    color.r, color.g, color.b, color.a = r, g, b, a
end

function node_text.proxyMethods:getAlign()
    return self.__node.text.align
end

function node_text.proxyMethods:setAlign(align)
    local valid = false
    for _, validAlign in ipairs(ALIGNS) do
        if align == validAlign then
            valid = true
            break
        end
    end
    if not valid then
        error("`align` must be one of '" .. table.concat(ALIGNS, "', '") .. "'")
    end
    self.__node.text.align = align
end


--
-- Draw
--

local theTransform = love.math.newTransform()

function node_text.proxyMethods:draw(transform)
    local node = self.__node

    -- Font
    self.__fontHolder = resource_loader.loadFont(node.text.fontUrl, node.text.fontSize)
    local font = self.__fontHolder.font

    -- Drawable
    local drawableText = self.__textDrawable
    if not self.__textDrawable then
        self.__textDrawable = love.graphics.newText(font)
        drawableText = self.__textDrawable
    end

    -- Update font
    if drawableText:getFont() ~= font then
        drawableText:setFont(font)
    end

    -- Update text, width, align
    local textChanged = self.__textLastText ~= node.text.text
    local widthChanged = self.__textLastWidth ~= node.width
    local alignChanged = self.__textLastAlign ~= node.text.align
    if textChanged or widthChanged or alignChanged then
        drawableText:setf(node.text.text, FONT_PIXELS_PER_UNIT * node.width, node.text.align)
        self.__textLastText = node.text.text
        self.__textLastWidth = node.width
        self.__textLastAlign = node.text.align
    end

    -- Color
    local color = node.text.color
    love.graphics.setColor(color.r, color.g, color.b, color.a)

    -- Transform
    theTransform:reset()
    theTransform:apply(transform)
    theTransform:translate(-0.5 * node.width, -0.5 * node.height):scale(1 / FONT_PIXELS_PER_UNIT)

    -- Draw!
    love.graphics.draw(drawableText, theTransform)
end


--
-- UI
--

function node_text.proxyMethods:uiTypePart(props)
    local node = self.__node

    self.__textSectionOpen = ui.section('text', {
        open = self.__textSectionOpen == nil and true or self.__textSectionOpen,
    }, function()
        -- Text
        ui.textArea('url', node.text.text, {
            onChange = props.validateChange(function(newText)
                node.text.text = newText
            end),
        })

        -- Font url
        ui.textInput('font url', node.text.fontUrl, {
            onChange = props.validateChange(function(newFontUrl)
                node.text.fontUrl = newFontUrl
            end),
        })

        -- Font size
        ui.slider('font size', node.text.fontSize, MIN_FONT_SIZE, MAX_FONT_SIZE, {
            onChange = props.validateChange(function(newFontSize)
                node.text.fontSize = math.max(MIN_FONT_SIZE, math.min(newFontSize, MAX_FONT_SIZE))
            end),
        })

        -- Color
        local color = node.text.color
        ui.colorPicker('color', color.r, color.g, color.b, color.a, {
            onChange = props.validateChange(function(newColor)
                color.r, color.g, color.b, color.a = newColor.r, newColor.g, newColor.b, newColor.a
            end),
        })

        -- Align
        ui.dropdown('align', node.text.align, ALIGNS, {
            onChange = props.validateChange(function(newAlign)
                node.text.align = newAlign
            end),
        })
        ui.box('spacer-1', { height = 100 }, function() end)
    end)
end


return node_text