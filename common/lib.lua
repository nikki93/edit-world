local lib = {}


lib.cs = require 'https://raw.githubusercontent.com/castle-games/share.lua/623c500de3cbfd544db9e6f2bdcd03b5b7e6f377/cs.lua'

lib.state = require 'https://raw.githubusercontent.com/castle-games/share.lua/623c500de3cbfd544db9e6f2bdcd03b5b7e6f377/state.lua'

lib.uuid = require 'https://raw.githubusercontent.com/Tieske/uuid/75f84281f4c45838f59fc2c6f893fa20e32389b6/src/uuid.lua'
lib.uuid.seed()

lib.sfxr = require 'https://raw.githubusercontent.com/nucular/sfxrlua/27511554ab63b834a8d8b34437c4ba5f0f589fdf/sfxr.lua'

lib.serpent = require 'https://raw.githubusercontent.com/pkulchenko/serpent/879580fb21933f63eb23ece7d60ba2349a8d2848/src/serpent.lua'


return lib