local function makeIndexableFunction(fn, baseTable)
  local table = baseTable and baseTable or {}

  return setmetatable(table, {
    __call = function(_, ...)
      return fn(...)
    end,
  })
end

return {
  makeIndexableFunction = makeIndexableFunction,
}