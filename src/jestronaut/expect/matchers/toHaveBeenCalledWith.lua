local tableImplode = require "jestronaut.utils.tables".implode

--- @param expect Expect
--- @param ... any
local function toHaveBeenCalledWith(expect, ...)
  local actual = expect.actual

  if not expect:checkEquals(true, actual:wasCalledWith(...)) then
    local tbl = {...}

    if #tbl == 0 then
      error("Expected " .. tostring(actual) .. " to have been called with no arguments but it was called with " .. tableImplode({actual:getCallArgs()}, ", "))
    else
      error("Expected " .. tostring(actual) .. " to have been called with " .. tableImplode(tbl, ", ") .. " but it was called with " .. tableImplode({actual:getCallArgs()}, ", "))
    end
  end

  return true
end

return {
  toHaveBeenCalledWith = toHaveBeenCalledWith,
  default = toHaveBeenCalledWith,
}