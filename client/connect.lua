local client = require 'client.init'
local locals = require 'client.locals'
local node_manager = require 'common.node_manager'
local player = require 'client.player'


local share = client.share
local home = client.home


function client.connect()
    home.player = player.init(share.players[client.id])

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