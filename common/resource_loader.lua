local resource_loader = {}


-- Load functions retain a 'holder' to which a strong reference must be held while the resource is in use


local defaultImage

if love.graphics then
    defaultImage = love.graphics.newImage('assets/checkerboard.png')
    defaultImage:setFilter('nearest', 'nearest')
end

local imageHolders = {
    linear = setmetatable({}, { __mode = 'v' }),
    nearest = setmetatable({}, { __mode = 'v' }),
}

function resource_loader.loadImage(url, filter)
    filter = filter or 'linear'
    local holder = imageHolders[filter][url]
    if not holder then
        holder = {}
        imageHolders[filter][url] = holder
        holder.image = defaultImage
        if url ~= '' then
            network.async(function()
                holder.image = love.graphics.newImage(url)
                holder.image:setFilter(filter, filter)
            end)
        end
    end
    return holder
end


return resource_loader