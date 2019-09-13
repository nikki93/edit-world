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

-- Load, play

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


-- SFXR

local SFXR_RANDOMIZERS = {
    'randomize', 'mutate', 'randomPickup',
    'randomLaser', 'randomExplosion', 'randomPowerup',
    'randomHit', 'randomJump', 'randomBlip',
}

for _, methodName in ipairs(SFXR_RANDOMIZERS) do
    node_sound.proxyMethods[methodName] = function(self)
        local node = self.__node
        assert(node.sound.sfxr, "`:" .. methodName .. "` can only be called on sfxr sounds")
        local sfxrInstance = lib.sfxr.newSound()
        sfxrInstance[methodName](sfxrInstance)
        node.sound.sfxr = table_utils.clone(sfxrInstance)
    end
end

local SFXR_PARAMETER_ROWS = {
    { 'volume', 'master', 0, 1, 'sound', 0, 1 },
    { 'envelope', 'attack', 0, 1, 'sustain', 0, 1 },
    { 'envelope', 'punch', 0, 1, 'decay', 0, 1 },
    { 'frequency', 'start', 0, 1, 'min', 0, 1 },
    { 'frequency', 'slide', -1, 1, 'dslide', -1, 1 },
    { 'change', 'amount', -1, 1, 'speed', 0, 1 },
    { 'duty', 'ratio', 0, 1, 'sweep', -1, 1 },
    { 'phaser', 'offset', -1, 1, 'sweep', -1, 1 },
    { 'lowpass', 'cutoff', 0, 1, 'sweep', -1, 1 },
    { 'lowpass', 'resonance', 0, 1 },
    { 'highpass', 'cutoff', 0, 1, 'sweep', -1, 1 },
    { 'vibrato', 'depth', 0, 1, 'speed', 0, 1 },
}

for _, row in ipairs(SFXR_PARAMETER_ROWS) do
    local key = row[1]
    for i = 2, #row, 3 do
        local subKey, min, max = row[i], row[i + 1], row[i + 2]
        local methodNameSuffix = key:gsub('^.', string.upper) .. subKey:gsub('^.', string.upper)

        node_sound.proxyMethods['get' .. methodNameSuffix] = function(self)
            local node = self.__node
            assert(node.sound.sfxr, "`:get" .. methodNameSuffix .. "` can only be called on sfxr sounds")
            return node.sound.sfxr[key][subKey]
        end

        node_sound.proxyMethods['set' .. methodNameSuffix] = function(self, value)
            local node = self.__node
            assert(node.sound.sfxr, "`:set" .. methodNameSuffix .. "` can only be called on sfxr sounds")
            node.sound.sfxr[key][subKey] = math.max(min, math.min(value, max))
        end
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
            ui.markdown('### randomizers')

            local function randomizerButton(methodName)
                if ui.button(methodName:gsub('^random(%u)', '%1'):lower()) then
                    props.validateChange(function()
                        self[methodName](self)
                        self:play()
                    end)()
                end
            end

            for i = 1, #SFXR_RANDOMIZERS, 3 do
                local r1, r2, r3 = SFXR_RANDOMIZERS[i], SFXR_RANDOMIZERS[i + 1], SFXR_RANDOMIZERS[i + 2]
                ui_utils.row(r1 .. r2 .. r3, function()
                    randomizerButton(r1)
                end, function()
                    randomizerButton(r2)
                end, function()
                    randomizerButton(r3)
                end)
            end

            ui.markdown('### parameters')

            ui.slider('repeat speed', node.sound.sfxr.repeatspeed, 0, 1, {
                step = 0.01,
                onChange = props.validateChange(function(newRepeatSpeed)
                    node.sound.sfxr.repeatspeed = newRepeatSpeed
                end),
            })

            local waveformMap = {
                square = 0, sawtooth = 1, sine = 2, noise = 3,
                [0] = 'square', [1] = 'sawtooth', [2] = 'sine', [3] = 'noise',
            }
            ui.dropdown('waveform', waveformMap[node.sound.sfxr.waveform], {
                'square', 'sawtooth', 'sine', 'noise',
            }, {
                onChange = props.validateChange(function(newWaveform)
                    node.sound.sfxr.waveform = waveformMap[newWaveform]
                end),
            })

            local function parameterSlider(key, subKey, min, max)
                ui.slider(key .. ' ' .. subKey, node.sound.sfxr[key][subKey], min, max, {
                    step = 0.01,
                    onChange = props.validateChange(function(newValue)
                        node.sound.sfxr[key][subKey] = newValue
                    end),
                })
            end

            local function parameterRow(key, subKey1, min1, max1, subKey2, min2, max2)
                ui_utils.row(key .. subKey1 .. subKey2, function()
                    parameterSlider(key, subKey1, min1, max1)
                end, function()
                    parameterSlider(key, subKey2, min2, max2)
                end)
            end

            for _, row in ipairs(SFXR_PARAMETER_ROWS) do
                if #row > 4 then
                    parameterRow(unpack(row))
                else
                    parameterSlider(unpack(row))
                end
            end
        end
    end)
end


return node_sound