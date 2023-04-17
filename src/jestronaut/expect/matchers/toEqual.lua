local asymetricMatcherLib = require "jestronaut.expect.asymetricmatchers.asymetricmatcher"

--- Determines whether two values are the same.
--- @param expect Expect
--- @param value any
--- @return boolean
local function toEqual(expect, value)
   -- Try raw equality first
  if expect.value == value then
    return true
  end

  if(asymetricMatcherLib.isMatcher(value))then
    if not asymetricMatcherLib.matches(value, expect.value) then
      error("Expected " .. tostring(expect.value) .. " to equal " .. tostring(value))
    end
  end

  return true
end

--- @param expect Expect
local function build(expect, customEqualityTesters)
  -- TODO: customEqualityTesters
  return function(expect, value)
    return toEqual(expect, value)
  end
end

return {
  toEqual = toEqual,
  build = build,
}