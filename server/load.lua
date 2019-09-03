local locals = require 'server.locals'
local node_manager = require 'common.node_manager'
local server = require 'server.init'
local settings = require 'common.settings'
local table_utils = require 'common.table_utils'


local share = server.share


function server.load()
    share.settings = table_utils.clone(settings.DEFAULTS)

    share.players = {}

    share.nodes = {}
    share.nodes.shared = {}
    share.nodes.locks = {}
    locals.nodeManager = node_manager.new({
        isServer = true,
        shared = share.nodes.shared,
        locks = share.nodes.locks,
    })
end