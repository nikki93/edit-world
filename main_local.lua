-- Entrypoint for a local server with a client connecting to it in the same process
USE_CASTLE_CONFIG = false
require 'server.main'
require 'client.main'