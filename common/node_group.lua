local node_base = require 'common.node_base'
local ui_utils = require 'common.ui_utils'
local ui = castle.ui


local node_group = {}


node_group.DEFAULTS = {
}


node_group.proxyMethods = setmetatable({}, { __index = node_base.proxyMethods })
node_group.proxyMetatable = { __index = node_group.proxyMethods }


--
-- Draw
--

function node_group.proxyMethods:draw(transform, cameraTransform)
end


--
-- UI
--

local sectionOpen = true

function node_group.proxyMethods:uiType(props)
    local node, nodeManager = self.__node, self.__nodeManager

    ui.tabs('tabs', function()
        ui.tab('rules', function()
        end)

        ui.tab('children', function()
        end)
    end)
end


return node_group