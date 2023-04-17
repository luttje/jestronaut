--- @class AsymetricMatcher
local ASYMETRIC_MATCHER_META
ASYMETRIC_MATCHER_META = {
  isAsymetricMatcher = true,
  inverse = false,
  sample = nil,

  new = function(sample, inverse)
    local instance = {
      sample = sample,
      inverse = inverse or false,
    }

    setmetatable(instance, ASYMETRIC_MATCHER_META)
    return instance
  end,

  asymmetricMatch = function(self, actual)
    error('asymmetricMatch must be implemented in subclass')
    -- e.g:
    -- local result = type(actual) == 'string' and string.find(self.sample, actual);

    -- return self.inverse and not result or result;
  end,

  __tostring = function(self)
    return 'Value' .. (self.inverse and 'Not' or '') .. 'Matching'
  end,

  getExpectedType = function(self)
    return 'unknown'
  end
}

ASYMETRIC_MATCHER_META.__index = ASYMETRIC_MATCHER_META

local function isMatcher(expected)
  return type(expected) == 'table' and expected.isAsymetricMatcher
end

local function matches(expected, actual)
  return expected:asymmetricMatch(actual)
end

return {
  ASYMETRIC_MATCHER_META = ASYMETRIC_MATCHER_META,
  isMatcher = isMatcher,
  matches = matches,
}