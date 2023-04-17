local asymetricMatcherLib = require "jestronaut.expect.asymetricmatchers.asymetricmatcher"

--- Determines whether two values are the same.
--- @param expect Expect
--- @param expected any
--- @return boolean
local function toEqual(expect, expected)
  local actual = expect.value

  -- Try raw equality first
  if (actual == expected) then
    return true
  end

  if(asymetricMatcherLib.isMatcher(expected))then
    if asymetricMatcherLib.matches(expected, actual) == expect.inverse then
      local actualValue = type(actual) == 'table' and ("table: '" .. table.concat(actual, ', ') .. "'") or tostring(actual)

      error("Expected " .. actualValue ..( expect.inverse and " not" or "") ..  " to equal " .. tostring(expected))
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