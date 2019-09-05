local node_base = {}


node_base.DEFAULTS = {
    type = 'image',
    tagsText = '',
    tags = {}, -- `tag` -> `true`
    parentId = nil,
    x = 0,
    y = 0,
    rotation = 0,
    depth = 100,
    width = 4,
    height = 4,
}


node_base.proxyMethods = setmetatable({}, {
    __index = function(self, k)
        return function()
            error("nodes of type '" .. self.__node.type .. "' do not have a `:" .. k .. "` method")
        end
    end,
})
node_base.proxyMetatable = { __index = node_base.proxyMethods }

function node_base.proxyMethods:getId()
    return self.__node.id
end


return node_base