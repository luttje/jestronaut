local asymmetricMatcherLib = require "jestronaut.expect.asymmetricmatchers.asymmetricmatcher"
local extendMetaTableIndex = require "jestronaut.utils.metatables".extendMetaTableIndex
local tableImplode = require "jestronaut.utils.tables".implode

--- @class ArrayContaining
local ARRAY_CONTAINING_META
ARRAY_CONTAINING_META = {
  customEqualityTesters = nil,

  new = function(sample, inverse, customEqualityTesters)
    local instance = {
      sample = sample,
      inverse = inverse or false,
      customEqualityTesters = customEqualityTesters or {},
    }

    setmetatable(instance, ARRAY_CONTAINING_META)
    return instance
  end,

  asymmetricMatch = function(self, actual)
    if not (type(self.sample) == 'table') then
      error('ArrayContaining sample must be a table')
    end

    if not (type(actual) == 'table') then
      return false
    end

    local foundAll = true

    for key, value in pairs(self.sample) do
      if not (actual[key] ~= nil) then
        foundAll = false
        break
      end

      if asymmetricMatcherLib.isMatcher(value) then
        if not asymmetricMatcherLib.matches(value, actual[key]) then
          foundAll = false
          break
        end
      else
        if not (actual[key] == value) then
          foundAll = false
          break
        end
      end
    end

    return self.inverse and not foundAll or foundAll
  end,

  __tostring = function(self)
    return 'Array' .. (self.inverse and 'Not' or '') .. 'Containing: \'' .. tableImplode(self.sample, ', ') .. "'"
  end,

  getExpectedType = function(self)
    return 'table'
  end,
}

extendMetaTableIndex(ARRAY_CONTAINING_META, asymmetricMatcherLib.ASYMMETRIC_MATCHER_META)

return {
  ARRAY_CONTAINING_META = ARRAY_CONTAINING_META,
  build = function(expect, customEqualityTesters)
    return function(expect, sample)
      return ARRAY_CONTAINING_META.new(sample, expect.inverse, customEqualityTesters)
    end
  end,
}