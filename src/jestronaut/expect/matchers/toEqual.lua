local asymmetricMatcherLib = require "jestronaut.expect.asymmetricmatchers.asymmetricmatcher"
local tableLib = require "jestronaut.utils.tables"

--- Determines whether two values are the same.
--- @param expect Expect
--- @param expected any
--- @return boolean
local function toEqual(expect, expected)
  local actual = expect.value

  if(asymmetricMatcherLib.isMatcher(expected))then
    if not expect:checkEquals(true, asymmetricMatcherLib.matches(expected, actual)) then
      local actualValue = type(actual) == 'table' and ("table: '" .. tableLib.implode(actual, ', ') .. "'") or tostring(actual)

      error("Expected " .. actualValue ..(expect.inverse and " not" or "") ..  " to equal " .. tostring(expected))
    end
  elseif (type(actual) == 'table' and type(actual) == type(expected)) then
    for key, value in pairs(expected) do
      if(asymmetricMatcherLib.isMatcher(value))then
        if not expect:checkEquals(true, asymmetricMatcherLib.matches(value, actual[key])) then
          local actualValue = type(actual[key]) == 'table' and ("table: '" .. tableLib.implode(actual[key], ', ') .. "'") or tostring(actual[key])

          error("Expected " .. actualValue ..(expect.inverse and " not" or "") ..  " to equal " .. tostring(value))
        end
      elseif (type(actual[key]) == 'table' and type(actual[key]) == type(value)) then
        if not expect:checkEquals(true, tableLib.equals(actual[key], value)) then
          error("Expected table '" .. tableLib.implode(actual[key], ', ') .. "'" .. (expect.inverse and " not " or "") .. " to equal '" .. tableLib.implode(value, ', ') .. "'")
        end
      else
        if not expect:checkEquals(value, actual[key]) then
          local actualValue = type(actual[key]) == 'table' and ("table: '" .. tableLib.implode(actual[key], ', ') .. "'") or tostring(actual[key])

          error("Expected " .. actualValue ..(expect.inverse and " not" or "") ..  " to equal " .. tostring(value))
        end
      end
    end
  else
    if not expect:checkEquals(expected, actual) then
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