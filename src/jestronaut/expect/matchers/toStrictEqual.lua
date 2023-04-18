local asymmetricMatcherLib = require "jestronaut.expect.asymmetricmatchers.asymmetricmatcher"
local tableLib = require "jestronaut.utils.tables"

--- Use .toStrictEqual to test that objects have the same structure and type.
--- Differences from .toEqual:
---     keys with undefined properties are checked, e.g. {a: undefined, b: 2} will not equal {b: 2};
---     undefined items are taken into account, e.g. [2] will not equal [2, undefined];
---     array sparseness is checked, e.g. [, 1] will not equal [undefined, 1];
---     object types are checked, e.g. a class instance with fields a and b will not equal a literal object with fields a and b.
--- @param expect Expect
--- @param expected any
--- @return boolean
local function toStrictEqual(expect, expected)
  local actual = expect.value

  if(asymmetricMatcherLib.isMatcher(expected))then
    if not expect:checkEquals(true, asymmetricMatcherLib.matches(expected, actual)) then
      local actualValue = type(actual) == 'table' and ("table: '" .. tableLib.implode(actual, ', ') .. "'") or tostring(actual)

      error("Expected " .. actualValue ..(expect.inverse and " not" or "") ..  " to equal " .. tostring(expected))
    end
  elseif (type(actual) == 'table' and type(actual) == type(expected)) then
    if not expect:checkEquals(true, tableLib.equals(actual, expected) and getmetatable(actual) == getmetatable(expected)) then
      error("Expected table " .. tableLib.implode(actual, ', ') .. (expect.inverse and " not " or "") .. "to equal " .. tableLib.implode(expected, ', '))
    end

    return true
  end

  return true
end

return {
  toStrictEqual = toStrictEqual,

  --- @param expect Expect
  build = function(expect, customEqualityTesters)
    -- TODO: customEqualityTesters
    return function(expect, sample)
      return toStrictEqual(expect, sample)
    end
  end,
}