local lib = require 'common.lib'
local table_utils = require 'common.table_utils'


local node_sound = {}


node_sound.DEFAULTS = {
    sfxr = table_utils.clone(lib.sfxr.newSound()),
    url = nil,
}


function node_sound.draw(node, transform)
end


return node_sound