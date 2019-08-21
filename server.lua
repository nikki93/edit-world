require 'common'


--- SERVER

local server = cs.server

if USE_CASTLE_CONFIG then
    server.useCastleConfig()
else
    server.enabled = true
    server.start('22122')
end

local share = server.share
local homes = server.homes


--- UTIL


--- LOAD

function server.load()
    do -- Players
        share.players = {}
    end

    do -- Nodes
        share.nodes = {}
    end
end


--- CONNECT

function server.connect(clientId)
    do -- New player
        share.players[clientId] = {}
        local player = share.players[clientId]

        player.x, player.y = 4 * G * (2 * math.random() - 1), 4 * G * (2 * math.random() - 1)
    end
end


--- DISCONNECT

function server.disconnect(clientId)
    do -- Remove player
        local player = share.players[clientId]
        share.players[clientId] = nil
    end
end


--- RECEIVE

function server.receive(clientId, msg)
    local player = share.players[clientId]
end


--- UPDATE

function server.update(dt)
    do -- Player mes
        for clientId, player in pairs(share.players) do
            player.me = homes[clientId].me
        end
    end

    do -- Player motion
        for clientId, player in pairs(share.players) do
            player.x, player.y = homes[clientId].x, homes[clientId].y
        end
    end
end
