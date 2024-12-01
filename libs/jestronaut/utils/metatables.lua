local function makeIndexableFunction(fn, baseTable)
    local table = baseTable and baseTable or {}

    return setmetatable(table, {
        __call = function(_, ...)
            return fn(...)
        end,
    })
end

local function extendMetaTableIndex(metatable, baseMetatable)
    metatable.__index = function(self, key)
        local ownMeta = rawget(metatable, key)

        if ownMeta ~= nil then
            return ownMeta
        end

        return baseMetatable[key]
    end
end

--- Relies on LuaLib from TypescriptToLua...
local function instanceOf(obj, classTbl)
    if type(classTbl) ~= "table" then
        error("Right-hand side of 'instanceof' is not an object", 0)
    end

    if type(obj) == "table" then
        local luaClass = obj.constructor
        while luaClass ~= nil do
            if luaClass == classTbl then
                return true
            end
            luaClass = luaClass.____super
        end
    end
    return false
end

return {
    makeIndexableFunction = makeIndexableFunction,
    extendMetaTableIndex = extendMetaTableIndex,
    instanceOf = instanceOf,
}
