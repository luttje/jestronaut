local wrapAndTagVarargsOrReturn = require "jestronaut/expect/asymmetricmatchers/varargsMatching".wrapAndTagVarargsOrReturn
local tableLib = require "jestronaut/utils/tables"

--- @param expect Expect
--- @param ... any
local function toHaveLastReturnedWith(expect, ...)
  local actual = expect.actual

  if not expect:checkEquals(true, actual:hasLastReturnedWith(...)) then
    local args = wrapAndTagVarargsOrReturn(...)

    if tableLib.count(args) == 0 then
      error("Expected " .. tostring(actual) .. " to have last returned with no arguments but it returned with " .. tableLib.implode({actual:getLastReturn()}, ", "))
    else
      error("Expected " .. tostring(actual) .. " to have last returned with " .. tableLib.implode(args, ", ") .. " but it returned with " .. tableLib.implode({actual:getLastReturn()}, ", "))
    end
  end

  return true
end

return {
  toHaveLastReturnedWith = toHaveLastReturnedWith,
  default = toHaveLastReturnedWith,
}