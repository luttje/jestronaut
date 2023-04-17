local tableImplode = require "jestronaut.utils.tables".implode

--- @param expect Expect
--- @param ... any
local function toHaveBeenNthCalledWith(expect, nthCall, ...)
  local actual = expect.value

  if not expect:checkEquals(true, actual:wasNthCalledWith(nthCall, ...)) then
    local tbl = {...}

    if #tbl == 0 then
      error("Expected " .. tostring(actual) .. " to have been called with no arguments (on call " .. nthCall .. ") but it was called with " .. tableImplode(actual:getCallArgs(), ", "))
    else
      error("Expected " .. tostring(actual) .. " to have been called with " .. tableImplode(tbl, ", ") .. " (on call " .. nthCall .. ") but it was called with " .. tableImplode(actual:getCallArgs(), ", "))
    end
  end

  return true
end

return {
  toHaveBeenCalledWith = toHaveBeenNthCalledWith,
  default = toHaveBeenNthCalledWith,
}