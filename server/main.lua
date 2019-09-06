debug_utils = require 'common.debug_utils'

require 'server.init' -- Must be called first!

-- Top-level events
require 'server.load'
require 'server.connect'
require 'server.disconnect'
require 'server.receive'
require 'server.changing'
require 'server.update'