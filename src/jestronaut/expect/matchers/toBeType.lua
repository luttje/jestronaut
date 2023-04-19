local isMockFunction = require "jestronaut.mock.mockfunction".isMockFunction

--- @param expect Expect
--- @param expected any
--- @return boolean
local function toBeType(expect, expected)
  if not expect:checkEquals(true, 
    expected == "function" and isMockFunction(expect.actual) or type(expect.actual) == expected) then
    error("Expected " .. tostring(expect.actual) .. " to be type " .. tostring(expected) .. " but it was type " .. tostring(type(expect.actual)))
  end

  return true
end

return {
  toBeType = toBeType,
  default = toBeType,
}