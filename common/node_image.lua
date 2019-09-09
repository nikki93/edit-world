local node_base = require 'common.node_base'


local node_image = {}


node_image.DEFAULTS = {
    url = '',
    color = { r = 1, g = 1, b = 1, a = 1 },
    smoothScaling = true,
    crop = false,
    cropX = 0,
    cropY = 0,
    cropWidth = 32,
    cropHeight = 32,
}


node_image.proxyMethods = setmetatable({}, { __index = node_base.proxyMethods })
node_image.proxyMetatable = { __index = node_image.proxyMethods }


--
-- Draw
--

if not CASTLE_SERVER then
    local defaultImage = love.graphics.newImage('assets/checkerboard.png')

    local imageCache = {}

    function node_image.imageFromUrl(url)
        local cached = imageCache[url]
        if not cached then
            cached = {}
            imageCache[url] = cached
            if url == '' then
                cached.image = defaultImage
            else
                network.async(function()
                    cached.image = love.graphics.newImage(url)
                end)
            end
        end
        return cached.image or defaultImage
    end

    local theTransform = love.math.newTransform()
    local theQuad = love.graphics.newQuad(0, 0, 32, 32, 32, 32)

    function node_image.proxyMethods:draw(transform)
        local node = self.__node

        -- Image
        local image = node_image.imageFromUrl(node.image.url)

        -- Filter
        local filter = image:getFilter()
        if node.image.smoothScaling and filter == 'nearest' then
            image:setFilter('linear', 'linear')
        end
        if not node.image.smoothScaling and filter == 'linear' then
            image:setFilter('nearest', 'nearest')
        end

        -- Crop
        local imageWidth, imageHeight = image:getWidth(), image:getHeight()
        if node.image.crop then
            theQuad:setViewport(node.image.cropX, node.image.cropY, node.image.cropWidth, node.image.cropHeight, imageWidth, imageHeight)
        else
            theQuad:setViewport(0, 0, imageWidth, imageHeight, imageWidth, imageHeight)
        end
        local quadX, quadY, quadWidth, quadHeight = theQuad:getViewport()

        -- Color
        local color = node.image.color
        love.graphics.setColor(color.r, color.g, color.b, color.a)

        -- Transform
        theTransform:reset()
        theTransform:apply(transform)
        theTransform:translate(-0.5 * node.width, -0.5 * node.height):scale(node.width / quadWidth, node.height / quadHeight)
        love.graphics.draw(image, theQuad, theTransform)
    end
else
    function node_image.proxyMethods:draw(transform)
    end
end


return node_image