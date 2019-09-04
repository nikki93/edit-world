local node_types = {}


node_types.base = require 'common.node_base'
node_types.image = require 'common.node_image'
node_types.text = require 'common.node_text'
node_types.group = require 'common.node_group'
node_types.sound = require 'common.node_sound'


return node_types