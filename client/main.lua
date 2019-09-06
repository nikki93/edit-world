debug_utils = require 'common.debug_utils'

require 'client.init' -- Must be called first!

-- Top-level events
require 'client.connect'
require 'client.changing'
require 'client.draw'
require 'client.update'
require 'client.mouse'
require 'client.keyboard'
require 'client.ui'