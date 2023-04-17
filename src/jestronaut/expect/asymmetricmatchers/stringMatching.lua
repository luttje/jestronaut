local ASYMMETRIC_MATCHER_META = require "jestronaut.expect.asymmetricmatchers.asymmetricmatcher".ASYMMETRIC_MATCHER_META
local extendMetaTableIndex = require "jestronaut.utils.metatables".extendMetaTableIndex

--- @class StringMatching
local STRING_MATCHING_META
STRING_MATCHING_META = {
  new = function(sample, inverse)
    local instance = {
      sample = sample,
      inverse = inverse or false,
    }

    setmetatable(instance, STRING_MATCHING_META)
    return instance
  end,

  asymmetricMatch = function(self, actual)
    local result = type(actual) == 'string' and string.find(actual, self.sample);

    return self.inverse and not result or result;
  end,

  __tostring = function(self)
    return 'String' .. (self.inverse and 'Not' or '') .. 'Matching'
  end,

  getExpectedType = function(self)
    return 'string'
  end,
}

extendMetaTableIndex(STRING_MATCHING_META, ASYMMETRIC_MATCHER_META)

return {
  STRING_MATCHING_META = STRING_MATCHING_META,
  default = function(expect, sample)
    return STRING_MATCHING_META.new(sample, expect.inverse)
  end,
}