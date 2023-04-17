local ASYMMETRIC_MATCHER_META = require "jestronaut.expect.asymmetricmatchers.asymmetricmatcher".ASYMMETRIC_MATCHER_META
local extendMetaTableIndex = require "jestronaut.utils.metatables".extendMetaTableIndex

--- @class CloseTo
local CLOSE_TO_MATCHING_META
CLOSE_TO_MATCHING_META = {
  new = function(sample, precision, inverse)
    if not (type(sample) == 'number') then
      error('Expected sample to be a number')
    end

    if precision == nil then
      precision = 2
    elseif not (type(precision) == 'number') then
      error('Expected precision to be a number')
    end

    local instance = {
      sample = sample,
      inverse = inverse or false,
      precision = precision,
    }

    setmetatable(instance, CLOSE_TO_MATCHING_META)
    return instance
  end,

  asymmetricMatch = function(self, actual)
    if not (type(actual) == 'number') then
      error('Expected actual to be a number')
    end

    local result = false
    if actual == math.huge and self.sample == math.huge then
      result = true
    elseif actual == -math.huge and self.sample == -math.huge then
      result = true
    else
      result = math.abs(self.sample - actual) < math.pow(10, -self.precision) / 2
    end

    print('CloseTo', self.sample, actual, self.precision, result)

    return self.inverse and not result or result
  end,

  __tostring = function(self)
    return 'Number' .. (self.inverse and 'Not' or '') .. 'CloseTo'
  end,

  getExpectedType = function(self)
    return 'number'
  end,
}

extendMetaTableIndex(CLOSE_TO_MATCHING_META, ASYMMETRIC_MATCHER_META)

return {
  CLOSE_TO_MATCHING_META = CLOSE_TO_MATCHING_META,
  default = function(expect, sample, precision)
    return CLOSE_TO_MATCHING_META.new(sample, precision, expect.inverse)
  end,
}