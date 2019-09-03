local node_base = {}


node_base.DEFAULTS = {
    type = 'image',
    tagsText = '',
    tags = {}, -- `tag` -> `true`
    parentId = nil,
    x = 0,
    y = 0,
    rotation = 0,
    depth = 0,
    width = 4 * G,
    height = 4 * G,
}


return node_base