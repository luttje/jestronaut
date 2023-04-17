local tableImplode = require "jestronaut.utils.tables".implode

--- @param expect Expect
--- @param ... any
local function toHaveBeenLastCalledWith(expect, ...)
  local actual = expect.value

  if not (actual:wasLastCalledWith(...)) then
    local tbl = {...}

    if #tbl == 0 then
      error("Expected " .. tostring(actual) .. " to have been called last with no arguments but it was called with " .. tableImplode(actual:getCallArgs(), ", "))
    else
      error("Expected " .. tostring(actual) .. " to have been called last with " .. tableImplode(tbl, ", ") .. " but it was called with " .. tableImplode(actual:getCallArgs(), ", "))
    end
  end

  return true
end

return {
  toHaveBeenCalledWith = toHaveBeenLastCalledWith,
  default = toHaveBeenLastCalledWith,
}