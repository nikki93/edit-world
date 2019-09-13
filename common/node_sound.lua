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


-- SFXR randomizers

local sfxrRandomizerMethodNames = {
    'randomize', 'mutate', 'randomPickup', 'randomLaser', 'randomExplosion',
    'randomPowerup', 'randomHit', 'randomJump', 'randomBlip',
}

for _, methodName in ipairs(sfxrRandomizerMethodNames) do
    node_sound.proxyMethods[methodName] = function(self)
        local node = self.__node
        assert(node.sound.sfxr, "`:" .. methodName .. "` can only be called on sfxr sounds")
        local sfxrInstance = lib.sfxr.newSound()
        sfxrInstance[methodName](sfxrInstance)
        node.sound.sfxr = table_utils.clone(sfxrInstance)
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
            ui.markdown('### randomize')

            local function randomizerButton(label, methodName)
                if ui.button(label) then
                    props.validateChange(function()
                        self[methodName](self)
                    end)()
                end
            end

            local function randomizerRow(l1, m1, l2, m2, l3, m3)
                ui_utils.row(l1 .. l2 .. l3, function()
                    randomizerButton(l1, m1)
                end, function()
                    randomizerButton(l2, m2)
                end, function()
                    randomizerButton(l3, m3)
                end)
            end

            randomizerRow('randomize', 'randomize', 'mutate', 'mutate', 'pickup', 'randomPickup')
            randomizerRow('laser', 'randomLaser', 'explosion', 'randomExplosion', 'powerup', 'randomPowerup')
            randomizerRow('hit', 'randomHit', 'jump', 'randomJump', 'blip', 'randomBlip')

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

            parameterRow('volume', 'master', 0, 1, 'sound', 0, 1)
            parameterRow('envelope', 'attack', 0, 1, 'sustain', 0, 1)
            parameterRow('envelope', 'punch', 0, 1, 'decay', 0, 1)
            parameterRow('frequency', 'start', 0, 1, 'min', 0, 1)
            parameterRow('frequency', 'slide', -1, 1, 'dslide', -1, 1)
            parameterRow('change', 'amount', -1, 1, 'speed', 0, 1)
            parameterRow('duty', 'ratio', 0, 1, 'sweep', -1, 1)
            parameterRow('phaser', 'offset', -1, 1, 'sweep', -1, 1)
            parameterRow('lowpass', 'cutoff', 0, 1, 'sweep', -1, 1)
            parameterSlider('lowpass', 'resonance', 0, 1)
            parameterRow('vibrato', 'depth', 0, 1, 'speed', 0, 1)
        end
    end)
end


return node_sound