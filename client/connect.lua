local client = require 'client.init'
local table_utils = require 'common.table_utils'
local locals = require 'client.locals'
local node_manager = require 'common.node_manager'


local share = client.share
local home = client.home


function client.connect()
    home.player = table_utils.clone(share.players[client.id])
    home.player.me = castle.user.getMe()

    home.nodes = {}
    home.nodes.controlled = {}
    locals.nodeManager = node_manager.new({
        isServer = false,
        shared = share.nodes.shared,
        locks = share.nodes.locks,
        controlled = home.nodes.controlled,
    })

    -- TODO(nikki): Handle `castle.post.getInitialPost()` being non-`nil`
end