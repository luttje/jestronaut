local asymmetricMatcherLib = require "jestronaut.expect.asymmetricmatchers.asymmetricmatcher"
local tableLib = require "jestronaut.utils.tables"

local function generateErrorMessage(expect, actualValue, expected)
  return "Expected " .. actualValue ..(expect.inverse and " not" or "") ..  " to equal " .. tostring(expected)
end

local function compareValues(expect, actual, expected, customEqualityTesters)
  if customEqualityTesters then
    for _, tester in ipairs(customEqualityTesters) do
      local result = tester(actual, expected)
      if result ~= nil then
        if not expect:checkEquals(result, expect.inverse) then
          local actualValue = type(actual) == 'table' and ("table: '" .. tableLib.implode(actual, ', ') .. "'") or tostring(actual)
          error(generateErrorMessage(expect, actualValue, expected))
        end
        
        return
      end
    end
  end

  if asymmetricMatcherLib.isMatcher(expected) then
    if not expect:checkEquals(true, asymmetricMatcherLib.matches(expected, actual)) then
      local actualValue = type(actual) == 'table' and ("table: '" .. tableLib.implode(actual, ', ') .. "'") or tostring(actual)
      error(generateErrorMessage(expect, actualValue, expected))
    end
  elseif type(actual) == 'table' and type(actual) == type(expected) then
    for key, value in pairs(expected) do
      if type(value) == 'table' and type(actual[key]) == 'table' then
        compareValues(expect, actual[key], value)
      else
        compareValues(expect, actual[key], value)
      end
    end
  else
    if not expect:checkEquals(expected, actual) then
      local actualValue = type(actual) == 'table' and ("table: '" .. tableLib.implode(actual, ', ') .. "'") or tostring(actual)
      error(generateErrorMessage(expect, actualValue, expected))
    end
  end
end

--- Determines whether two values are the same.
--- @param expect Expect
--- @param expected any
--- @return boolean
local function toEqual(expect, expected, customEqualityTesters)
  compareValues(expect, expect.actual, expected, customEqualityTesters)
  return true
end

return {
  toEqual = toEqual,

  --- @param expect Expect
  build = function(expect, customEqualityTesters)
    return function(expect, sample)
      return toEqual(expect, sample, customEqualityTesters)
    end
  end,
}