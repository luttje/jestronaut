local wrapAndTagVarargsOrReturn = require "jestronaut/expect/asymmetricmatchers/varargsMatching".wrapAndTagVarargsOrReturn
local asymmetricMatcherLib = require "jestronaut/expect/asymmetricmatchers/asymmetricmatcher"
local tableLib = require "jestronaut/utils/tables"

local function generateErrorMessage(expect, actual, expected)
  local actualValue = type(actual) == 'table' and ("table: '" .. tableLib.implode(actual, ', ') .. "'") or tostring(actual)
  local expectedValue = type(expected) == 'table' and ("table: '" .. tableLib.implode(expected, ', ') .. "'") or tostring(expected)

  return "Expected " .. actualValue ..(expect.inverse and " not" or "") ..  " to equal " .. tostring(expectedValue)
end

local function compareValues(expect, actual, customEqualityTesters, expected)
  if customEqualityTesters then
    for _, tester in ipairs(customEqualityTesters) do
      local result = tester(actual, expected)
      if result ~= nil then
        if not expect:checkEquals(result, expect.inverse) then
          error(generateErrorMessage(expect, actual, expected))
        end
        
        return
      end
    end
  end

  if asymmetricMatcherLib.isMatcher(expected) then
    if not expect:checkEquals(true, asymmetricMatcherLib.matches(expected, actual)) then
      error(generateErrorMessage(expect, actual, expected))
    end
  elseif type(actual) == 'table' and type(actual) == type(expected) then
    for key, value in pairs(expected) do
      if type(value) == 'table' and type(actual[key]) == 'table' then
        compareValues(expect, actual[key], customEqualityTesters, value)
      else
        compareValues(expect, actual[key], customEqualityTesters, value)
      end
    end
  else
    if not expect:checkEquals(expected, actual) then
      error(generateErrorMessage(expect, actual, expected))
    end
  end
end

--- Determines whether two values are the same.
--- @param expect Expect
--- @param expected any
--- @return boolean
local function toEqual(expect, customEqualityTesters, ...)
  compareValues(expect, expect.actual, customEqualityTesters or {}, wrapAndTagVarargsOrReturn(...))
  return true
end

return {
  toEqual = toEqual,

  --- @param expect Expect
  build = function(expect, customEqualityTesters)
    return function(expect, ...)
      return toEqual(expect, customEqualityTesters or {}, ...)
    end
  end,
}