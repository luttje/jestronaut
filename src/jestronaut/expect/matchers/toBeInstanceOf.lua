local metatableLib = require "jestronaut.utils.metatables"

--- 
--- @param expect Expect
--- @param value any
--- @return boolean
local function toBeInstanceOf(expect, value)
  local actual = expect.actual

  if type(value) == 'table' then
    if not expect:checkEquals(true, value.constructor and metatableLib.instanceOf(actual, value.constructor) or metatableLib.instanceOf(actual, value)) then
      error("Expected " .. tostring(actual) .. " to be an instance of " .. tostring(value))
    end
  elseif not expect:checkEquals(type(actual), value) then
    error("Expected " .. tostring(actual) .. " to be an instance of " .. tostring(value))
  end


  return true
end

return {
  toBeInstanceOf = toBeInstanceOf,
  default = toBeInstanceOf,
}