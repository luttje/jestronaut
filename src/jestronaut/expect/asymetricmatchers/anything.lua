local ASYMETRIC_MATCHER_META = require "jestronaut.expect.asymetricmatchers.asymetricmatcher".ASYMETRIC_MATCHER_META
local extendMetaTableIndex = require "jestronaut.utils.metatables".extendMetaTableIndex

--- @class Anything
local ANYTHING_META
ANYTHING_META = {
  new = function(sample)
    local instance = {
      sample = sample,
    }

    setmetatable(instance, ANYTHING_META)
    return instance
  end,

  asymmetricMatch = function(self, actual)
    return actual ~= nil
  end,

  __tostring = function(self)
    return 'Anything'
  end,

  getExpectedType = function(self)
    return 'any'
  end,
}

extendMetaTableIndex(ANYTHING_META, ASYMETRIC_MATCHER_META)

return {
  ANYTHING_META = ANYTHING_META,
  anything = function(expect, sample)
    return ANYTHING_META.new(sample)
  end,
}