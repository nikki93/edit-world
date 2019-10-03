local lib = {}


lib.cs = require 'https://raw.githubusercontent.com/castle-games/share.lua/949bd274ce6ed5acf1fa30331c1af97b7e6052d7/cs.lua'

lib.state = require 'https://raw.githubusercontent.com/castle-games/share.lua/949bd274ce6ed5acf1fa30331c1af97b7e6052d7/state.lua'

lib.uuid = require 'https://raw.githubusercontent.com/Tieske/uuid/75f84281f4c45838f59fc2c6f893fa20e32389b6/src/uuid.lua'
lib.uuid.seed()

lib.sfxr = require 'https://raw.githubusercontent.com/nikki93/sfxrlua/b7377e848fdf6b86811ed28deedeafc50fa16ca0/sfxr.lua'

lib.serpent = require 'https://raw.githubusercontent.com/pkulchenko/serpent/879580fb21933f63eb23ece7d60ba2349a8d2848/src/serpent.lua'

lib.marshal = require 'marshal'


return lib