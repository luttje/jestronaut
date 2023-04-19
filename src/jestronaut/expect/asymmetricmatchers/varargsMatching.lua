local asymmetricMatcherLib = require "jestronaut.expect.asymmetricmatchers.asymmetricmatcher"
local extendMetaTableIndex = require "jestronaut.utils.metatables".extendMetaTableIndex
local functionLib = require "jestronaut.utils.functions"
local tableLib = require "jestronaut.utils.tables"

--- @class VarargsMatching
local VARARGS_MATCHING_META
VARARGS_MATCHING_META = {
  new = function(sample, inverse)
    if(sample == nil) then
      error("VarargsMatching: sample cannot be nil")
    end

    local instance = {
      sample = sample,
      inverse = inverse or false,
    }
    setmetatable(instance, VARARGS_MATCHING_META)
    return instance
  end,

  asymmetricMatch = function(self, actual)
    local sampleArgs = self.sample
    local actualArgs
    
    if functionLib.isWrappedVarargsTable(self.sample) then
      sampleArgs = self.sample.args
    end

    if functionLib.isWrappedVarargsTable(actual) then
      actualArgs = actual.args
    elseif type(actual) == "table" then
      actualArgs = actual
    end

    if actualArgs == nil then
      return false
    end

    return self.inverse ~= functionLib.isWrappedVarargsEqual(sampleArgs, actualArgs)
  end,

  __tostring = function(self)
    return 'Vararg' .. (self.inverse and 'Not' or '') .. 'Matching ("' .. tableLib.implode(self.sample, ", ") .. '")'
  end,

  getExpectedType = function(self)
    return 'vararg'
  end,
}

extendMetaTableIndex(VARARGS_MATCHING_META, asymmetricMatcherLib.ASYMMETRIC_MATCHER_META)

return {
  VARARGS_MATCHING_META = VARARGS_MATCHING_META,
  default = function(expect, ...)
    local sample = {...}

    if #sample == 1 then
      sample = sample[1]
    end

    return VARARGS_MATCHING_META.new(sample, expect.inverse)
  end,
}