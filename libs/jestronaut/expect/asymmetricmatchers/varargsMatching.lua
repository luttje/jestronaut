local asymmetricMatcherLib = require "jestronaut/expect/asymmetricmatchers/asymmetricmatcher"
local extendMetaTableIndex = require "jestronaut/utils/metatables".extendMetaTableIndex
local tableLib = require "jestronaut/utils/tables"

--- @class VarargsMatching
local VARARGS_MATCHING_META

--- Wrap varargs in a table and tag them. That way we can identify them later and unpack them.
--- @vararg any
--- @return table
local function wrapAndTagVarargsOrReturn(...)
  local varargs = {...}

  if #varargs == 0 then
    return nil
  elseif #varargs == 1 then
    return varargs[1]
  end

  return VARARGS_MATCHING_META.new(varargs)
end

--- Check if a table is a wrapped varargs table.
--- @param value table
--- @return boolean
local function isVarargsMatcher(value)
  return type(value) == "table" and value.isVarargsMatching
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
      return tableLib.equals(varargsOrValue, expectedVarargsOrValue)
    end
  end

  return varargsOrValue == expectedVarargsOrValue
end

--- Unpack varargs if they are wrapped in a table and tagged.
--- @param varargsTableOrValue VarargsMatching|any
--- @return VarargsMatching|any
local function unwrapVarargsOrReturn(varargsTableOrValue)
  if type(varargsTableOrValue) == "table" and isVarargsMatcher(varargsTableOrValue) then
    return unpack(varargsTableOrValue.varargs)
  end

  return varargsTableOrValue
end

VARARGS_MATCHING_META = {
  isVarargsMatching = true,

  new = function(varargs, inverse)
    if(varargs == nil) then
      error("VarargsMatching: varargs cannot be nil")
    end

    local instance = {
      varargs = varargs,
      inverse = inverse or false,
    }

    setmetatable(instance, VARARGS_MATCHING_META)
    return instance
  end,

  asymmetricMatch = function(self, actual)
    if actual == nil then
      return false
    end

    if not isVarargsMatcher(actual) then
      if #self.varargs == 1 then
        return self.inverse ~= isWrappedVarargsEqual(self.varargs[1], actual)
      end

      return false
    end

    return self.inverse ~= tableLib.equals(self.varargs, actual.varargs)
  end,

  __tostring = function(self)
    return 'Vararg' .. (self.inverse and 'Not' or '') .. 'Matching ("' .. tableLib.implode(self.varargs, ", ") .. '")'
  end,

  getExpectedType = function(self)
    return 'vararg'
  end,
}

extendMetaTableIndex(VARARGS_MATCHING_META, asymmetricMatcherLib.ASYMMETRIC_MATCHER_META)

return {
  default = function(expect, ...)
    local varargs = {...}

    return VARARGS_MATCHING_META.new(varargs, expect.inverse)
  end,
  
  wrapAndTagVarargsOrReturn = wrapAndTagVarargsOrReturn,
  isWrappedVarargsEqual = isWrappedVarargsEqual,
  unwrapVarargsOrReturn = unwrapVarargsOrReturn,
  isVarargsMatcher = isVarargsMatcher,
}