local asymetricMatcherLib = require "jestronaut.expect.asymetricmatchers.asymetricmatcher"
local tableImplode = require "jestronaut.utils.tables".implode

--- Determines whether two values are the same.
--- @param expect Expect
--- @param expected any
--- @return boolean
local function toEqual(expect, expected)
  local actual = expect.value

  -- Try raw equality first
  if expect:checkEquals(actual, expected) then
    return true
  end

  if(asymetricMatcherLib.isMatcher(expected))then
    if not expect:checkEquals(true, asymetricMatcherLib.matches(expected, actual)) then
      local actualValue = type(actual) == 'table' and ("table: '" .. tableImplode(actual, ', ') .. "'") or tostring(actual)

      error("Expected " .. actualValue ..(expect.inverse and " not" or "") ..  " to equal " .. tostring(expected))
    end
  end

  return true
end

return {
  toEqual = toEqual,

  --- @param expect Expect
  build = function(expect, customEqualityTesters)
    -- TODO: customEqualityTesters
    return function(expect, sample)
      return toEqual(expect, sample)
    end
  end,
}