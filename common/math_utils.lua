local math_utils = {}


function math_utils.getTranslationFromTransform(transform)
    return transform:transformPoint(0, 0)
end

function math_utils.getRotationFromTransform(transform)
    local ox, oy = transform:transformPoint(0, 0)
    local ux, uy = transform:transformPoint(1, 0)
    return math.atan2(uy - oy, ux - ox)
end

function math_utils.getScaleFromTransform(transform)
    local ox, oy = transform:transformPoint(0, 0)
    local ux, uy = transform:transformPoint(1, 0)
    local dx, dy = ux - ox, uy - oy
    return math.sqrt(dx * dx + dy * dy)
end


return math_utils