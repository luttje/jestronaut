local wrapAndTagVarargsOrReturn = require "jestronaut.expect.asymmetricmatchers.varargsMatching".wrapAndTagVarargsOrReturn
local tableLib = require "jestronaut.utils.tables"

--- @param expect Expect
--- @param ... any
local function toHaveBeenLastCalledWith(expect, ...)
  local actual = expect.actual

  if not expect:checkEquals(true, actual:wasLastCalledWith(...)) then
    local args = wrapAndTagVarargsOrReturn(...)

    if tableLib.count(args) == 0 then
      error("Expected " .. tostring(actual) .. " to have been called last with no arguments but it was called with " .. tableLib.implode({actual:getCallArgs()}, ", "))
    else
      error("Expected " .. tostring(actual) .. " to have been called last with " .. tableImplode(args, ", ") .. " but it was called with " .. tableLib.implode({actual:getCallArgs()}, ", "))
    end
  end

  return true
end

return {
  toHaveBeenCalledWith = toHaveBeenLastCalledWith,
  default = toHaveBeenLastCalledWith,
}