cs = require 'https://raw.githubusercontent.com/castle-games/share.lua/623c500de3cbfd544db9e6f2bdcd03b5b7e6f377/cs.lua'


--- CONSTANTS

G = 32              -- Grid unit size

WALK_SPEED = 6 * G


--- GRAPHICS UTILS

if love.graphics then
    -- `love.graphics.stacked([arg], func)` calls `func` between `love.graphics.push([arg])` and
    -- `love.graphics.pop()` while being resilient to errors
    function love.graphics.stacked(argOrFunc, funcOrNil)
        love.graphics.push(funcOrNil and argOrFunc)
        local succeeded, err = pcall(funcOrNil or argOrFunc)
        love.graphics.pop()
        if not succeeded then
            error(err, 0)
        end
    end
end


--- COMMON LOGIC
