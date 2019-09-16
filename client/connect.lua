local client = require 'client.init'
local locals = require 'client.locals'
local node_manager = require 'common.node_manager'
local player = require 'client.player'


local share = client.share
local home = client.home


function client.connect()
    -- Player
    home.player = player.init(share.players[client.id])

    -- Nodes
    home.nodes = {}
    home.nodes.controlled = {}
    locals.nodeManager = node_manager.new({
        isServer = false,
        shared = share.nodes.shared,
        locks = share.nodes.locks,
        controlled = home.nodes.controlled,
        clientId = client.id,
    })

    -- Apply diffs that `client.changing` deferred
    if locals.deferredShareDiff then -- If `client.changing` gets a diff before `client.connect` it defers it for later
        client.changing(locals.deferredShareDiff)
        locals.deferredShareDiff = nil
    end

    -- If a post was opened, let the server know
    local initialPost = castle.post.getInitialPost()
    if initialPost then
        client.send('postOpened', initialPost)
    end

    -- Loaded
    network.async(function()
        locals.loaded = true
    end)
end