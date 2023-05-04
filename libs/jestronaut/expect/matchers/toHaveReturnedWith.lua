local wrapAndTagVarargsOrReturn = require "jestronaut/expect/asymmetricmatchers/varargsMatching".wrapAndTagVarargsOrReturn
local tableLib = require "jestronaut/utils/tables"

--- @param expect Expect
--- @param ... any
local function toHaveReturnedWith(expect, ...)
  local actual = expect.actual

  if not expect:checkEquals(true, actual:hasReturnedWith(...)) then
    local args = wrapAndTagVarargsOrReturn(...)

    if tableLib.count(args) == 0 then
      error("Expected " .. tostring(actual) .. " to have returned with no arguments but it returned with " .. tableLib.implode({actual:getAllReturnValues()}, ", "))
    else
      error("Expected " .. tostring(actual) .. " to have returned with " .. tableLib.implode(args, ", ") .. " but it returned with " .. tableLib.implode({actual:getAllReturnValues()}, ", "))
    end
  end

  return true
end

return {
  toHaveReturnedWith = toHaveReturnedWith,
  default = toHaveReturnedWith,
}