local ASYMETRIC_MATCHER_META = require "jestronaut.expect.asymetricmatchers.asymetricmatcher".ASYMETRIC_MATCHER_META
local extendMetaTableIndex = require "jestronaut.utils.metatables".extendMetaTableIndex

--- @class StringMatching
local STRING_MATCHING_META = setmetatable({
  new = function(sample, inverse)
    local instance = {
      sample = sample,
      inverse = inverse or false,
    }

    setmetatable(instance, self)
    return instance
  end,

  asymmetricMatch = function(self, other)
    local result = type(other) == 'string' and string.find(self.sample, other);

    return self.inverse and not result or result;
  end,

  __tostring = function(self)
    return 'String' .. (this.inverse and 'Not' or '') .. 'Matching'
  end,

  getExpectedType = function(self)
    return 'string'
  end,
}, ASYMETRIC_MATCHER_META)

extendMetaTableIndex(STRING_MATCHING_META, ASYMETRIC_MATCHER_META)

local function build(self)
  return function(sample, inverse)
    return STRING_MATCHING_META.new(self, sample, inverse)
  end
end

return {
  STRING_MATCHING_META = STRING_MATCHING_META,
  build = build,
}