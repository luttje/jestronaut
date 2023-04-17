local ASYMETRIC_MATCHER_META = require "jestronaut.expect.asymetricmatchers.asymetricmatcher".ASYMETRIC_MATCHER_META
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
    local result = type(actual) == 'string' and string.find(self.sample, actual);

    return self.inverse and not result or result;
  end,

  __tostring = function(self)
    return 'String' .. (self.inverse and 'Not' or '') .. 'Matching'
  end,

  getExpectedType = function(self)
    return 'string'
  end,
}

extendMetaTableIndex(STRING_MATCHING_META, ASYMETRIC_MATCHER_META)

return {
  STRING_MATCHING_META = STRING_MATCHING_META,
  stringMatching = function(expect, sample, inverse)
    return STRING_MATCHING_META.new(sample, inverse)
  end,
}