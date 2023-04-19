local asymmetricMatcherLib = require "jestronaut.expect.asymmetricmatchers.asymmetricmatcher"
local tableLib = require "jestronaut.utils.tables"

--- Replace a function with a callback function that is called after the original function is called, allowing us to spy on the function.
--- @param fn fun(...): any
--- @param callback fun(success: boolean, ...): void
local function makeFunctionShim(fn, callback)
  return function(...)
    local success, result = pcall(fn, ...)

    callback(success, ...)

    if not success then
      error(result, 2)
    end

    return result
  end
end

--- Captures the vararg results of a (x)pcall function call into a table.
--- @param success boolean
--- @vararg any
--- @return boolean, table
local function captureSafeCallInTable(success, ...)
  local output = {}
  
  for key, value in ipairs({...}) do
    output[key] = value
  end

  return success, output
end


--- Wrap varargs in a table and tag them. That way we can identify them later and unpack them.
--- @vararg any
--- @return table
local function wrapAndTagVarargsOrReturn(...)
  local args = {...}

  if #args == 0 then
    return nil
  elseif #args == 1 then
    return args[1]
  end

  local varargs = {
    __jestronaut_varargs = true,
    args = args
  }

  return (require "jestronaut.expect.asymmetricmatchers.varargsMatching".VARARGS_MATCHING_META).new(varargs)
end

--- Compares varargs or values with the expected values or value
--- @param varargsOrValue table|any
--- @param expectedVarargsOrValue table|any
--- @return boolean
local function isWrappedVarargsEqual(varargsOrValue, expectedVarargsOrValue)
  if varargsOrValue == nil or expectedVarargsOrValue == nil then
    return expectedVarargsOrValue == varargsOrValue
  end

  if asymmetricMatcherLib.isMatcher(varargsOrValue) then
    return asymmetricMatcherLib.matches(varargsOrValue, expectedVarargsOrValue)
  elseif asymmetricMatcherLib.isMatcher(expectedVarargsOrValue) then
    return asymmetricMatcherLib.matches(expectedVarargsOrValue, varargsOrValue)
  end

  if type(varargsOrValue) == "table" then
    if type(expectedVarargsOrValue) == "table" then
      if varargsOrValue.__jestronaut_varargs and expectedVarargsOrValue.__jestronaut_varargs then
        return tableLib.equals(varargsOrValue.args, expectedVarargsOrValue.args)
      end

      return tableLib.equals(varargsOrValue, expectedVarargsOrValue)
    end
  end

  return varargsOrValue == expectedVarargsOrValue
end

--- Unpack varargs if they are wrapped in a table and tagged.
--- @param varargsTableOrValue table|any
--- @return any
local function unwrapVarargsOrReturn(varargsTableOrValue)
  if type(varargsTableOrValue) == "table" and varargsTableOrValue.__jestronaut_varargs then
    return unpack(varargsTableOrValue.args)
  end

  return varargsTableOrValue
end

local function isWrappedVarargsTable(value)
  return type(value) == "table" and value.__jestronaut_varargs
end

return {
  makeFunctionShim = makeFunctionShim,
  captureSafeCallInTable = captureSafeCallInTable,

  wrapAndTagVarargsOrReturn = wrapAndTagVarargsOrReturn,
  isWrappedVarargsEqual = isWrappedVarargsEqual,
  unwrapVarargsOrReturn = unwrapVarargsOrReturn,
  isWrappedVarargsTable = isWrappedVarargsTable,
}