local ASYMETRIC_MATCHER_META = require "jestronaut.expect.asymetricmatchers.asymetricmatcher".ASYMETRIC_MATCHER_META
local extendMetaTableIndex = require "jestronaut.utils.metatables".extendMetaTableIndex

--- @class Any
local ANY_META
ANY_META = {
  new = function(sample)
    if sample == nil then
      error(
        'any() expects to be passed a constructor function. ' ..
          'Please pass one or use anything() to match any object.'
      )
    end

    local instance = {
      sample = sample,
    }

    setmetatable(instance, ANY_META)
    return instance
  end,

  --- Matches anything that was created with the given constructor or if it's a primitive that is of the passed type
  asymmetricMatch = function(self, other)
    if self.sample == 'string' then
      return type(other) == 'string'
    end

    if self.sample == 'number' then
      return type(other) == 'number'
    end

    if self.sample == 'function' then
      return type(other) == 'function'
    end

    if self.sample == 'table' then
      return type(other) == 'table'
    end

    if self.sample == 'boolean' then
      return type(other) == 'boolean'
    end

    if type(self.sample) == 'table' and type(other) == 'table' and other.constructor then
      return self.sample == other.constructor
    end

    return type(other) == self.sample
  end,

  __tostring = function(self)
    return 'Any ' .. self:getExpectedType()
  end,

  getExpectedType = function(self)
    if self.sample == 'string' then
      return 'string'
    end

    if self.sample == 'number' then
      return 'number'
    end

    if self.sample == 'function' then
      return 'function'
    end

    if self.sample == 'table' then
      return 'table'
    end

    if self.sample == 'boolean' then
      return 'boolean'
    end

    if type(self.sample) == 'table' and self.sample.name then
      return self.sample.name
    end

    return self.sample
  end,
}

extendMetaTableIndex(ANY_META, ASYMETRIC_MATCHER_META)

return {
  ANY_META = ANY_META,
  any = function(expect, sample)
    return ANY_META.new(sample)
  end,
}