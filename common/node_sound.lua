local lib = require 'common.lib'
local table_utils = require 'common.table_utils'
local node_base = require 'common.node_base'
local ui_utils = require 'common.ui_utils'
local ui = castle.ui


local node_sound = {}


node_sound.DEFAULTS = {
    sfxr = table_utils.clone(lib.sfxr.newSound()),
    url = nil,
}


node_sound.proxyMethods = setmetatable({}, { __index = node_base.proxyMethods })
node_sound.proxyMetatable = { __index = node_sound.proxyMethods }


--
-- Methods
--

local sfxrHolders = setmetatable({}, { __mode = 'v' })

function node_sound.proxyMethods:load()
    local node = self.__node

    if node.sound.sfxr then -- SFXR?
        local marshalled = lib.marshal.encode(table_utils.clone(node.sound.sfxr))
        local holder = sfxrHolders[marshalled]
        if not holder then
            holder = {}
            sfxrHolders[marshalled] = holder

            local sfxrInstance = lib.sfxr.newSound()
            for memberName, memberValue in pairs(node.sound.sfxr) do
                if type(memberValue) == 'table' or type(memberValue) == 'userdata' then
                    local t = sfxrInstance[memberName]
                    for k, v in pairs(memberValue) do
                        t[k] = v
                    end
                else
                    assert(type(sfxrInstance[memberName]) == type(memberValue),
                        'internal error: type mismatch between sfxr parameters')
                    sfxrInstance[memberName] = memberValue
                end
            end

            holder.source = love.audio.newSource(sfxrInstance:generateSoundData())
        end
        self.__sourceHolder = holder
    end
end

function node_sound.proxyMethods:play()
    self:load()
    if self.__sourceHolder then
        self.__sourceHolder.source:clone():play()
    end
end


--
-- Draw
--

function node_sound.proxyMethods:draw(transform)
end


--
-- UI
--

function node_sound.proxyMethods:uiTypePart(props)
    local node = self.__node

    self.__soundSectionOpen = ui.section('sound', {
        open = self.__soundSectionOpen == nil and true or self.__soundSectionOpen,
    }, function()
        if ui.button('play') then
            self:play()
        end

        if node.sound.sfxr then -- SFXR?
        end
    end)
end


return node_sound