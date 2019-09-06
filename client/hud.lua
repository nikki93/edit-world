local graphics_utils = require 'client.graphics_utils'
local mode = require 'client.mode'
local hud_sheet = require 'client.hud_sheet'


local hud = {}


--
-- Font
--

local font 

function hud.getFont()
    return font
end

function hud.reloadFonts()
    font = love.graphics.newFont('assets/font.ttf', 12, 'mono')
    font:setFilter('nearest', 'nearest')
end
hud.reloadFonts()


--
-- Slice drawing
--

local function drawSlice(sliceName, x, y, w, h, quadName)
    local quad = hud_sheet.slices[sliceName].quads[quadName or 'single']
    assert(quad, 'internal error: quad not found -- may need `quadName`')
    local quadX, quadY, quadWidth, quadHeight = quad:getViewport()
    if not w then
        w, h = quadWidth, quadHeight
    end
    if not h then
        h = quadHeight / quadWidth * w
    end
    love.graphics.draw(hud_sheet.image, quad, x, y, 0, w / quadWidth, h / quadHeight)
end

local function draw3x3Slice(sliceName, x, y, w, h, noMiddle)
    local slice = hud_sheet.slices[sliceName]
    local w1, w2, w3, h1, h2, h3 = slice.w1, slice.w2, slice.w3, slice.h1, slice.h2, slice.h3

    -- Corners
    drawSlice(sliceName, x, y, w1, h1, 'top_left')
    drawSlice(sliceName, x + w - w3, y, w3, h1, 'top_right')
    drawSlice(sliceName, x, y + h - h3, w1, h3, 'bottom_left')
    drawSlice(sliceName, x + w - w3, y + h - h3, w3, h3, 'bottom_right')

    -- Edges
    drawSlice(sliceName, x + w1, y, w - w1 - w3, h1, 'top')
    drawSlice(sliceName, x + w1, y + h - h3, w - w1 - w3, h3, 'bottom')
    drawSlice(sliceName, x, y + h1, w1, h - h1 - h3, 'left')
    drawSlice(sliceName, x + w - w3, y + h1, w3, h - h1 - h3, 'right')

    -- Middle
    if not noMiddle then
        drawSlice(sliceName, x + w1, y + h1, w - w1 - w3, h - h1 - h3, 'middle')
    end
end


--
-- Mode buttons
--

local windowW, windowH = love.graphics.getDimensions()

local MODE_BUTTON_PADDING = 8
local MODE_BUTTON_GAP = 8

local MODE_BUTTON_HEIGHT = font:getHeight() + 2 * MODE_BUTTON_PADDING
local MODE_BUTTON_WIDTH = 0
for _, modeName in pairs(mode.order) do
    local requiredWidth = font:getWidth(modeName) + 2 * MODE_BUTTON_PADDING 
    if requiredWidth > MODE_BUTTON_WIDTH then
        MODE_BUTTON_WIDTH = requiredWidth
    end
end

local MODE_BUTTONS_LEFT = 0.5 * windowW - 0.5 * (MODE_BUTTON_WIDTH * #mode.order + MODE_BUTTON_GAP * (#mode.order - 1))
local MODE_BUTTONS_TOP = 20

local modeButtons = {}
for i = 1, #mode.order do
    local modeName = mode.order[i]
    table.insert(modeButtons, {
        modeName = modeName,
        x = MODE_BUTTONS_LEFT + (i - 1) * (MODE_BUTTON_WIDTH + MODE_BUTTON_GAP),
        y = MODE_BUTTONS_TOP,
        w = MODE_BUTTON_WIDTH,
        h = MODE_BUTTON_HEIGHT,
    })
end

local function drawModeButtons()
    graphics_utils.safePushPop('all', function()
        love.graphics.setFont(font)
        for i = 1, #modeButtons do
            local b = modeButtons[i]

            -- Pick slice
            local sliceName = 'button_normal'
            if mode.getMode() == b.modeName then
                sliceName = 'button_selected'
            end

            -- Background
            draw3x3Slice(sliceName, b.x, b.y, b.w, b.h)

            -- Mode text
            love.graphics.printf(b.modeName, b.x + 2, b.y + MODE_BUTTON_PADDING, MODE_BUTTON_WIDTH, 'center')

            -- Hotkey text
            graphics_utils.safePushPop('all', function()
                local slice = hud_sheet.slices[sliceName]
                love.graphics.translate(b.x + MODE_BUTTON_WIDTH, b.y + MODE_BUTTON_HEIGHT)
                love.graphics.scale(0.5, 0.5)
                local hotkeyText = tostring(i)
                love.graphics.translate(-font:getWidth(hotkeyText) - slice.w3, -font:getHeight() - slice.h3 - 4)
                love.graphics.print(hotkeyText)
            end)
        end
    end)
end

local function checkModeButtonClick(x, y, mouseButton)
    if mouseButton == 1 then
        for _, b in ipairs(modeButtons) do
            if b.x <= x and x <= b.x + b.w and b.y <= y and y <= b.y + b.h then
                mode.setMode(b.modeName)
                return true
            end
        end
    end
    return false
end


--
-- Draw
--

function hud.draw()
    drawModeButtons()
end


--
-- Mouse
--

function hud.mousepressed(x, y, mouseButton, isTouch, presses)
    if checkModeButtonClick(x, y, mouseButton) then
        return true
    end
    return false
end

function hud.mousereleased(x, y, mouseButton, isTouch, presses)
end

function hud.mousemoved(x, y, dx, dy, isTouch)
end


return hud