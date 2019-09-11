local client = require 'client.init'
local graphics_utils = require 'common.graphics_utils'
local camera = require 'client.camera'
local locals = require 'client.locals'
local space = require 'client.space'
local node_types = require 'common.node_types'
local player = require 'client.player'
local mode = require 'client.mode'
local hud = require 'client.hud'
local debug_draw = require 'client.debug_draw'


local share = client.share
local home = client.home


local function drawBackground()
    local c = share.settings.backgroundColor
    love.graphics.clear(c.r, c.g, c.b)
end


local debugHUDText = love.graphics.newText(hud.getFont())

local function drawDebugHUD()
    local text = ''

    text = text .. '\nfps: ' .. love.timer.getFPS()

    local zoomFactor = camera.getZoomFactor()
    if zoomFactor < 1 then
        text = text .. '\nzoom in: ' .. (1 / zoomFactor) .. 'x'
    end
    if zoomFactor > 1 then
        text = text .. '\nzoom out: ' .. zoomFactor .. 'x'
    end

    local windowW, windowH = love.graphics.getDimensions()
    debugHUDText:clear()
    debugHUDText:setFont(hud.getFont())
    debugHUDText:addf(text, windowW - 20, 'right')
    love.graphics.setColor(0, 0, 0)
    love.graphics.draw(debugHUDText, 0, windowH - debugHUDText:getHeight() - 20)
end


function client.draw()
    -- Connecting / loading?
    if not client.connected then
        love.graphics.print('connecting...', 20, 20)
        return
    end
    if not locals.loaded then
        love.graphics.print('loading...', 20, 20)
        return
    end

    -- Background
    graphics_utils.safePushPop('all', function()
        drawBackground()
    end)

    -- Camera transform
    graphics_utils.safePushPop('all', function()
        love.graphics.applyTransform(camera.getTransform())

        -- Collect nodes in depth order
        local nodesInDepthOrder = {}
        locals.nodeManager:forEach(function(id, node)
            table.insert(nodesInDepthOrder, node)
        end)
        table.sort(nodesInDepthOrder, space.compareDepth)

        -- Nodes
        graphics_utils.safePushPop('all', function()
            for _, node in ipairs(nodesInDepthOrder) do
                locals.nodeManager:getProxy(node):draw(space.getWorldSpace(node).transform)
            end
        end)

        -- Mode-specific node overlays
        graphics_utils.safePushPop('all', function()
            mode.drawNodeOverlays(nodesInDepthOrder)
        end)

        -- Players
        graphics_utils.safePushPop('all', function()
            for clientId, p in pairs(share.players) do
                if client.id == clientId and home.player then
                    p = home.player
                end
                player.draw(p)
            end
        end)

        -- Debug (world-space)
        graphics_utils.safePushPop('all', function()
            debug_draw.flushWorldSpace()
        end)
    end)

    -- HUD
    graphics_utils.safePushPop('all', function()
        hud.draw()
    end)

    -- Debug HUD
    graphics_utils.safePushPop('all', function()
        drawDebugHUD()
    end)
end