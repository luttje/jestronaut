local asymmetricMatcherLib = require "jestronaut.expect.asymmetricmatchers.asymmetricmatcher"
local extendMetaTableIndex = require "jestronaut.utils.metatables".extendMetaTableIndex
local tableLib = require "jestronaut.utils.tables"

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


--- @class VarargsMatching
local VARARGS_MATCHING_META
VARARGS_MATCHING_META = {
  new = function(sample, inverse)
    if(sample == nil) then
      error("VarargsMatching: sample cannot be nil")
    end

    if not isWrappedVarargsTable(sample) then
      error("VarargsMatching: sample must be a wrapped varargs table")
    end

    local instance = {
      sample = sample,
      inverse = inverse or false,
    }
    setmetatable(instance, VARARGS_MATCHING_META)
    return instance
  end,

  asymmetricMatch = function(self, actual)
    if isWrappedVarargsTable(actual) then
      return self.inverse and not tableLib.equals(self.sample.args, actual.args) or tableLib.equals(self.sample.args, actual.args)
    end

    -- If the other thing is also a VarargsMatching, then we can compare the samples
    if asymmetricMatcherLib.isMatcher(actual) and actual.getExpectedType and actual.getExpectedType() == "vararg" then
      return self.inverse and not tableLib.equals(self.sample.args, actual.sample.args) or tableLib.equals(self.sample.args, actual.sample.args)
    end

    -- If the other thing is a table, then we can compare the values
    if type(actual) == "table" then
      return self.inverse and not tableLib.equals(self.sample.args, actual) or tableLib.equals(self.sample.args, actual)
    end

    return self.inverse
  end,

  __tostring = function(self)
    return 'Vararg' .. (self.inverse and 'Not' or '') .. 'Matching'
  end,

  getExpectedType = function(self)
    return 'vararg'
  end,
}

extendMetaTableIndex(VARARGS_MATCHING_META, asymmetricMatcherLib.ASYMMETRIC_MATCHER_META)

return {
  VARARGS_MATCHING_META = VARARGS_MATCHING_META,
  default = function(expect, sample)
    return VARARGS_MATCHING_META.new(sample, expect.inverse)
  end,
}