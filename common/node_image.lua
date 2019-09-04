local node_image = {}


node_image.DEFAULTS = {
    url = 'https://github.com/nikki93/edit-world/raw/66e4850578fd46cbb9f3c1db30611981f26906e5/checkerboard.png',
    color = { r = 1, g = 1, b = 1, a = 1 },
    smoothScaling = true,
    crop = false,
    cropX = 0,
    cropY = 0,
    cropWidth = 32,
    cropHeight = 32,
}


local defaultImage
if love.graphics then
    defaultImage = love.graphics.newImage('checkerboard.png')
end

local imageCache = {}

local function imageFromUrl(url)
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

local theQuad
if love.graphics then
    theQuad = love.graphics.newQuad(0, 0, 32, 32, 32, 32)
end

function node_image.draw(node, transform)
    local image = imageFromUrl(node.image.url)

    -- Filter
    local filter = image:getFilter()
    if node.image.smoothScaling and filter == 'nearest' then
        image:setFilter('linear')
    end
    if not node.image.smoothScaling and filter == 'linear' then
        image:setFilter('nearest')
    end

    -- Crop
    local iw, ih = image:getWidth(), image:getHeight()
    if node.image.crop then
        theQuad:setViewport(node.image.cropX, node.image.cropY, node.image.cropWidth, node.image.cropHeight, iw, ih)
    else
        theQuad:setViewport(0, 0, iw, ih, iw, ih)
    end
    local qx, qy, qw, qh = theQuad:getViewport()

    -- Scale
    local scale = math.min(node.width / qw, node.height / qh)

    -- Color
    local c = node.image.color
    love.graphics.setColor(c.r, c.g, c.b, c.a)

    -- Transform
    theTransform:reset()
    theTransform:apply(transform)
    theTransform:translate(-0.5 * node.width, -0.5 * node.height):scale(scale)
    love.graphics.draw(image, theQuad, theTransform)
end


return node_image