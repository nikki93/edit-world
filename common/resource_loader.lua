local resource_loader = {}


-- Load functions retain a 'holder' to which a strong reference must be held while the resource is in use


local defaultImage = love.graphics and love.graphics.newImage('assets/checkerboard.png')

local imageHolders = setmetatable({}, { __mode = 'v' })

function resource_loader.loadImage(url)
    local n = 0
    for k, v in pairs(imageHolders) do
        n = n + 1
    end
    debug_utils.throttledPrint('# image holders', n)

    local holder = imageHolders[url]
    if not holder then
        holder = {}
        imageHolders[url] = holder
        holder.image = defaultImage
        if url ~= '' then
            network.async(function()
                holder.image = love.graphics.newImage(url)
            end)
        end
    end
    return holder
end


return resource_loader