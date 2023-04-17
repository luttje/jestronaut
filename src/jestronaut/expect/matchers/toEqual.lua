local asymmetricMatcherLib = require "jestronaut.expect.asymmetricmatchers.asymmetricmatcher"
local tableLib = require "jestronaut.utils.tables"

--- Determines whether two values are the same.
--- @param expect Expect
--- @param expected any
--- @return boolean
local function toEqual(expect, expected)
  local actual = expect.value

  -- Try raw equality first
  if (type(actual) == 'table' and type(actual) == type(expected)) then
    if not expect:checkEquals(true, tableLib.equals(actual, expected)) then
      error("Expected table " .. tableLib.implode(actual, ', ') .. (expect.inverse and "not " or "") .. "to equal " .. tableLib.implode(expected, ', '))
    end

    return true
  end

  if(asymmetricMatcherLib.isMatcher(expected))then
    print(asymmetricMatcherLib.matches(expected, actual))
    if not expect:checkEquals(true, asymmetricMatcherLib.matches(expected, actual)) then
      local actualValue = type(actual) == 'table' and ("table: '" .. tableLib.implode(actual, ', ') .. "'") or tostring(actual)

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