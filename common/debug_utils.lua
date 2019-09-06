local debug_utils = {}


local lastPrintTimes = {}

function debug_utils.throttledPrint(printId, ...)
    local currTime = love.timer.getTime()
    local lastPrintTime = lastPrintTimes[printId]
    if not lastPrintTime or currTime - lastPrintTime > 1 then
        print('[' .. printId .. ']', ...)
        lastPrintTimes[printId] = currTime
    end
end


return debug_utils