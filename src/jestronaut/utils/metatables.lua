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

return {
  makeIndexableFunction = makeIndexableFunction,
  extendMetaTableIndex = extendMetaTableIndex,
}