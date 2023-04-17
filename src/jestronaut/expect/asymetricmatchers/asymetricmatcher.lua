--- @class AsymetricMatcher
local ASYMETRIC_MATCHER_META = {
  isAsymetricMatcher = true,
  inverse = false,
  sample = nil,

  new = function(sample, inverse)
    local instance = {
      sample = sample,
      inverse = inverse or false,
    }

    setmetatable(instance, self)
    return instance
  end,

  asymmetricMatch = function(self, other)
    error('asymmetricMatch must be implemented in subclass')
    -- e.g:
    -- local result = type(other) == 'string' and string.find(self.sample, other);

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

return {
  ASYMETRIC_MATCHER_META = ASYMETRIC_MATCHER_META,
}